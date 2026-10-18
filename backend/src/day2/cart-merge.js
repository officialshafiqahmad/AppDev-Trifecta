const crypto = require('crypto');
const { canonical } = require('../canonical');
const { signDay2, day2Salt } = require('./sign');
const { guestWriteDecision } = require('./guest');

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isInt(value) {
  return typeof value === 'number' && Number.isInteger(value);
}

function validateCartMerge(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ['body'] };
  const fields = [];
  if (typeof body.guest_token !== 'string' || !body.guest_token.startsWith('guest_')) fields.push('guest_token');
  if (typeof body.registered_user_id !== 'string' || body.registered_user_id.length < 1) {
    fields.push('registered_user_id');
  }
  const cart = body.guest_cart;
  if (!Array.isArray(cart) || cart.length < 1 || cart.length > 10 || cart.some((item) => (
    !isPlainObject(item)
    || typeof item.variant_id !== 'string'
    || item.variant_id.length < 1
    || !isInt(item.quantity)
    || item.quantity < 1
  ))) {
    fields.push('guest_cart');
  }
  let testWriteBlock = true;
  if (Object.prototype.hasOwnProperty.call(body, 'test_write_block')) {
    if (typeof body.test_write_block !== 'boolean') fields.push('test_write_block');
    else testWriteBlock = body.test_write_block;
  }
  if (fields.length > 0) return { ok: false, fields };
  return {
    ok: true,
    guest_token: body.guest_token,
    registered_user_id: body.registered_user_id,
    guest_cart: cart.map((item) => ({ variant_id: item.variant_id, quantity: item.quantity })),
    test_write_block: testWriteBlock,
  };
}

function cartHash(request) {
  return crypto.createHash('sha256').update(canonical({
    guest_token: request.guest_token,
    registered_user_id: request.registered_user_id,
    guest_cart: request.guest_cart,
  })).digest('hex');
}

function combineCart(existing, incoming) {
  const quantities = new Map();
  const order = [];
  for (const item of existing) {
    if (!quantities.has(item.variant_id)) order.push(item.variant_id);
    quantities.set(item.variant_id, (quantities.get(item.variant_id) || 0) + item.quantity);
  }
  for (const item of incoming) {
    if (!quantities.has(item.variant_id)) order.push(item.variant_id);
    quantities.set(item.variant_id, (quantities.get(item.variant_id) || 0) + item.quantity);
  }
  return { quantities, order };
}

function buildMergeBody(request, items, write) {
  const totalItems = items.reduce((sum, item) => sum + item.quantity, 0);
  const subtotal = items.reduce((sum, item) => sum + (item.quantity * item.unit_price_minor), 0);
  const body = {
    guest_token: request.guest_token,
    write_block_verified: write.verified,
    write_rejection_code: write.code,
    cart_merged: true,
    active_cart: {
      user_id: request.registered_user_id,
      currency: 'PKR',
      total_items: totalItems,
      subtotal_minor: subtotal,
      items,
    },
  };
  body.signature = signDay2(day2Salt(), request.guest_token, {
    cart_merged: true,
    guest_token: request.guest_token,
    registered_user_id: request.registered_user_id,
    total_items: totalItems,
    write_rejection_code: write.code,
  });
  return body;
}

async function handleCartMerge(pool, body) {
  const parsed = validateCartMerge(body);
  if (!parsed.ok) {
    return {
      error: {
        status: 400,
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed.',
        details: { fields: parsed.fields },
      },
    };
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`guest-merge:${parsed.guest_token}`]);
    const hash = cartHash(parsed);
    const prior = await client.query(
      'SELECT registered_user_id, cart_hash, response FROM guest_merges WHERE guest_token = $1',
      [parsed.guest_token],
    );
    if (prior.rowCount === 1) {
      const row = prior.rows[0];
      if (row.registered_user_id === parsed.registered_user_id && row.cart_hash === hash) {
        await client.query('COMMIT');
        return { status: 200, body: row.response };
      }
      await client.query('ROLLBACK');
      return {
        error: {
          status: 409,
          code: 'GUEST_TOKEN_ALREADY_MERGED',
          message: 'Guest token was already merged with a different request.',
          details: { guest_token: parsed.guest_token },
        },
      };
    }

    const user = await client.query(
      `SELECT player_id AS id FROM players WHERE player_id = $1
       UNION
       SELECT user_id AS id FROM users WHERE user_id = $1`,
      [parsed.registered_user_id],
    );
    if (user.rowCount === 0) {
      await client.query('ROLLBACK');
      return {
        error: {
          status: 404,
          code: 'PLAYER_NOT_FOUND',
          message: `Player ${parsed.registered_user_id} was not found.`,
          details: { player_id: parsed.registered_user_id },
        },
      };
    }

    await client.query('SELECT user_id FROM user_carts WHERE user_id = $1 FOR UPDATE', [parsed.registered_user_id]);
    const cartRes = await client.query('SELECT items FROM user_carts WHERE user_id = $1', [parsed.registered_user_id]);
    const existing = cartRes.rowCount === 1 && Array.isArray(cartRes.rows[0].items) ? cartRes.rows[0].items : [];
    const combined = combineCart(existing, parsed.guest_cart);
    const variantIds = combined.order;
    const variants = await client.query(
      'SELECT variant_id, price_minor, stock, reserved FROM variants WHERE variant_id = ANY($1::text[])',
      [variantIds],
    );
    const byId = new Map(variants.rows.map((row) => [row.variant_id, row]));
    for (const item of parsed.guest_cart) {
      if (!byId.has(item.variant_id)) {
        await client.query('ROLLBACK');
        return {
          error: {
            status: 404,
            code: 'VARIANT_NOT_FOUND',
            message: `Variant ${item.variant_id} was not found.`,
            details: { variant_id: item.variant_id },
          },
        };
      }
    }
    for (const [variantId, quantity] of combined.quantities) {
      const variant = byId.get(variantId);
      const available = variant.stock - variant.reserved;
      if (quantity > available) {
        await client.query('ROLLBACK');
        return {
          error: {
            status: 409,
            code: 'OUT_OF_STOCK',
            message: `Variant ${variantId} does not have enough stock.`,
            details: { variant_id: variantId },
          },
        };
      }
    }

    const items = combined.order.map((variantId) => ({
      variant_id: variantId,
      quantity: combined.quantities.get(variantId),
      unit_price_minor: byId.get(variantId).price_minor,
    }));
    const decision = guestWriteDecision(parsed.guest_token);
    const write = {
      verified: parsed.test_write_block && decision.blocked && decision.status === 403,
      code: decision.blocked ? decision.status : 0,
    };
    const response = buildMergeBody(parsed, items, write);

    if (cartRes.rowCount === 1) {
      await client.query('UPDATE user_carts SET items = $2::jsonb WHERE user_id = $1', [
        parsed.registered_user_id,
        JSON.stringify(items),
      ]);
    } else {
      await client.query('INSERT INTO user_carts (user_id, items) VALUES ($1, $2::jsonb)', [
        parsed.registered_user_id,
        JSON.stringify(items),
      ]);
    }
    await client.query(
      `UPDATE guest_sessions SET merged = TRUE, status = 'merged' WHERE guest_token = $1`,
      [parsed.guest_token],
    );
    await client.query(
      `INSERT INTO guest_merges (guest_token, registered_user_id, cart_hash, response)
       VALUES ($1, $2, $3, $4::jsonb)`,
      [parsed.guest_token, parsed.registered_user_id, hash, JSON.stringify(response)],
    );
    await client.query('COMMIT');
    return { status: 200, body: response };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  buildMergeBody,
  cartHash,
  combineCart,
  handleCartMerge,
  validateCartMerge,
};
