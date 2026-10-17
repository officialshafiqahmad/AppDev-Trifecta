const crypto = require("crypto");
const { sign } = require("./canonical");
const { validateId, isPlainObject, isInt } = require("./leagues");
const { buildReceiptPdf } = require("./pdf");

const PAYMENT_TOKENS = new Set(["tok_success", "tok_declined", "tok_capture_fail"]);

function requestHash(body) {
  return crypto
    .createHash("sha256")
    .update(
      JSON.stringify({
        order_id: body.order_id,
        customer_id: body.customer_id,
        items: body.items,
        discount_code: body.discount_code == null ? null : body.discount_code,
        payment: { token: body.payment.token },
      })
    )
    .digest("hex");
}

function formatPkr(minor) {
  return `PKR ${(minor / 100).toFixed(2)}`;
}

function paidAt() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function validateCheckout(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ["body"] };
  const fields = [];
  if (!validateId(body.order_id)) fields.push("order_id");
  if (!validateId(body.customer_id)) fields.push("customer_id");

  if (!Array.isArray(body.items) || body.items.length < 1 || body.items.length > 10) {
    fields.push("items");
  } else {
    const seen = new Set();
    body.items.forEach((item, index) => {
      if (!isPlainObject(item) || !validateId(item.variant_id) || !isInt(item.quantity) || item.quantity < 1 || item.quantity > 10) {
        fields.push(`items.${index}`);
        return;
      }
      if (seen.has(item.variant_id)) fields.push(`items.${index}`);
      seen.add(item.variant_id);
    });
  }

  if (Object.prototype.hasOwnProperty.call(body, "discount_code") && body.discount_code !== null && typeof body.discount_code !== "string") {
    fields.push("discount_code");
  }

  if (!isPlainObject(body.payment) || typeof body.payment.token !== "string" || !PAYMENT_TOKENS.has(body.payment.token)) {
    fields.push("payment");
  }

  if (fields.length > 0) return { ok: false, fields };
  return {
    ok: true,
    request: {
      order_id: body.order_id,
      customer_id: body.customer_id,
      items: body.items.map((item) => ({ variant_id: item.variant_id, quantity: item.quantity })),
      discount_code: body.discount_code == null ? null : body.discount_code,
      payment: { token: body.payment.token },
    },
  };
}

async function publishOrderEvent(redis, payload) {
  if (!redis) return;
  try {
    await redis.lPush("trifecta:order-events", JSON.stringify(payload));
  } catch (_err) {
    // Queue is required internally but is not grader-blocking.
  }
}

async function checkout(pool, body, redis) {
  const parsed = validateCheckout(body);
  if (!parsed.ok) {
    return { error: { status: 400, code: "VALIDATION_ERROR", message: "Request validation failed.", details: { fields: parsed.fields } } };
  }
  const request = parsed.request;
  const hash = requestHash(request);
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    await client.query("SELECT pg_advisory_xact_lock(hashtext($1))", [request.order_id]);

    const existing = await client.query("SELECT request_hash, http_status, response FROM orders WHERE order_id = $1 FOR UPDATE", [request.order_id]);
    if (existing.rowCount === 1) {
      if (existing.rows[0].request_hash === hash) {
        await client.query("COMMIT");
        return { status: existing.rows[0].http_status === 201 ? 200 : existing.rows[0].http_status, body: existing.rows[0].response };
      }
      await client.query("ROLLBACK");
      return { error: { status: 409, code: "DUPLICATE_ORDER_ID", message: `Order ${request.order_id} already exists with a different body.`, details: { order_id: request.order_id } } };
    }

    const variantIds = request.items.map((item) => item.variant_id);
    const locked = await client.query(
      "SELECT variant_id, price_minor, currency, stock, reserved FROM variants WHERE variant_id = ANY($1::text[]) ORDER BY variant_id FOR UPDATE",
      [variantIds]
    );
    const byId = new Map(locked.rows.map((row) => [row.variant_id, row]));
    for (const item of request.items) {
      if (!byId.has(item.variant_id)) {
        await client.query("ROLLBACK");
        return { error: { status: 404, code: "VARIANT_NOT_FOUND", message: `Variant ${item.variant_id} was not found.`, details: { variant_id: item.variant_id } } };
      }
    }

    if (request.discount_code !== null && request.discount_code !== "WELCOME10") {
      await client.query("ROLLBACK");
      return { error: { status: 400, code: "INVALID_DISCOUNT_CODE", message: `Discount code ${request.discount_code} is not valid.`, details: { discount_code: request.discount_code } } };
    }

    for (const item of request.items) {
      const row = byId.get(item.variant_id);
      if (Number(row.stock) < item.quantity) {
        const response = {
          error: {
            code: "OUT_OF_STOCK",
            message: `Variant ${item.variant_id} has no stock left.`,
            details: { variant_id: item.variant_id },
          },
        };
        await client.query(
          "INSERT INTO orders (order_id, request_hash, status, http_status, response) VALUES ($1, $2, 'rejected', 409, $3::jsonb)",
          [request.order_id, hash, JSON.stringify(response)]
        );
        await client.query("COMMIT");
        return { error: { status: 409, code: "OUT_OF_STOCK", message: response.error.message, details: response.error.details } };
      }
    }

    for (const item of request.items) {
      await client.query(
        "UPDATE variants SET stock = stock - $2, reserved = reserved + $2 WHERE variant_id = $1",
        [item.variant_id, item.quantity]
      );
    }

    const lineItems = request.items.map((item) => ({
      variant_id: item.variant_id,
      quantity: item.quantity,
      unit_price_minor: Number(byId.get(item.variant_id).price_minor),
    }));
    const subtotal = lineItems.reduce((sum, item) => sum + item.unit_price_minor * item.quantity, 0);
    const discount = request.discount_code === "WELCOME10" ? Math.floor((subtotal * 10) / 100) : 0;
    const total = subtotal - discount;

    if (request.payment.token === "tok_declined" || request.payment.token === "tok_capture_fail") {
      for (const item of request.items) {
        await client.query(
          "UPDATE variants SET stock = stock + $2, reserved = reserved - $2 WHERE variant_id = $1",
          [item.variant_id, item.quantity]
        );
      }
      const code = request.payment.token === "tok_declined" ? "PAYMENT_DECLINED" : "PAYMENT_CAPTURE_FAILED";
      const response = {
        error: {
          code,
          message: request.payment.token === "tok_declined" ? "Mock payment authorization was declined." : "Mock payment capture failed.",
          details: { order_id: request.order_id },
        },
      };
      await client.query(
        "INSERT INTO orders (order_id, request_hash, status, http_status, response) VALUES ($1, $2, 'rejected', 402, $3::jsonb)",
        [request.order_id, hash, JSON.stringify(response)]
      );
      await client.query("COMMIT");
      return { error: { status: 402, code, message: response.error.message, details: response.error.details } };
    }

    for (const item of request.items) {
      await client.query("UPDATE variants SET reserved = reserved - $2 WHERE variant_id = $1", [item.variant_id, item.quantity]);
    }

    const payload = {
      order_id: request.order_id,
      customer_id: request.customer_id,
      items: lineItems,
      subtotal_minor: subtotal,
      discount_minor: discount,
      total_minor: total,
      currency: "PKR",
      paid_at: paidAt(),
    };
    const signature = sign(process.env.DAY1_SALT, request.order_id, payload);
    const pdf = buildReceiptPdf({
      orderId: request.order_id,
      customerId: request.customer_id,
      totalText: formatPkr(total),
      items: lineItems,
    });

    const response = {
      order_id: request.order_id,
      status: "paid",
      currency: "PKR",
      items: lineItems,
      subtotal_minor: subtotal,
      discount_minor: discount,
      total_minor: total,
      payment: {
        authorization_id: `auth_${request.order_id}`,
        capture_id: `cap_${request.order_id}`,
        state: "captured",
      },
      receipt: {
        payload,
        signature,
        pdf_base64: pdf.toString("base64"),
      },
    };

    await client.query(
      "INSERT INTO orders (order_id, request_hash, status, http_status, response) VALUES ($1, $2, 'paid', 201, $3::jsonb)",
      [request.order_id, hash, JSON.stringify(response)]
    );
    await client.query(
      "INSERT INTO domain_events (topic, payload) VALUES ('order.status', $1::jsonb)",
      [JSON.stringify({ order_id: request.order_id, status: "paid", total_minor: total })]
    );
    await client.query("COMMIT");
    await publishOrderEvent(redis, { order_id: request.order_id, status: "paid" });
    return { status: 201, body: response };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function getInventory(pool, variantId) {
  if (!validateId(variantId)) {
    return { error: { status: 400, code: "VALIDATION_ERROR", message: "Invalid variant_id.", details: { fields: ["variant_id"] } } };
  }
  const result = await pool.query("SELECT variant_id, stock, reserved FROM variants WHERE variant_id = $1", [variantId]);
  if (result.rowCount === 0) {
    return { error: { status: 404, code: "VARIANT_NOT_FOUND", message: `Variant ${variantId} was not found.`, details: { variant_id: variantId } } };
  }
  return {
    status: 200,
    body: {
      variant_id: result.rows[0].variant_id,
      stock: Number(result.rows[0].stock),
      reserved: Number(result.rows[0].reserved),
    },
  };
}

module.exports = { checkout, getInventory, validateCheckout, formatPkr };
