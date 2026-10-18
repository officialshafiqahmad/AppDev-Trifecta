const { signDay2, day2Salt } = require('./sign');

const DICTIONARY = new Set([
  'badword',
  'porn',
  'scam',
  'fuck',
  'shit',
  'bitch',
  'asshole',
  'idiotspam',
]);

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isInt(value) {
  return typeof value === 'number' && Number.isInteger(value);
}

function normalizeToken(token) {
  return token
    .replace(/[\u200b\u200c\u200d\ufeff]/g, '')
    .replace(/[@＠]/g, 'a')
    .replace(/0/g, 'o')
    .replace(/[1!]/g, 'i')
    .replace(/3/g, 'e')
    .replace(/\$/g, 's')
    .replace(/[_.\-*]/g, '')
    .toLowerCase();
}

function isFlood(text) {
  return /(.)\1{3,}/i.test(text) || /!{3,}|\?{3,}/.test(text);
}

function maskProfanity(text) {
  let flagged = false;
  const masked = text.replace(/[A-Za-z0-9@$!_.*\-\u200b\u200c\u200d\ufeff]+/g, (token) => {
    if (!DICTIONARY.has(normalizeToken(token))) return token;
    flagged = true;
    return '***';
  });
  return { text: masked, flagged };
}

function validateModeration(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ['body'] };
  const fields = [];
  if (typeof body.chat_room_id !== 'string' || body.chat_room_id.length < 1) fields.push('chat_room_id');
  if (!Array.isArray(body.incoming_messages) || body.incoming_messages.some((message) => (
    !isPlainObject(message)
    || typeof message.message_id !== 'string'
    || typeof message.sender !== 'string'
    || typeof message.text !== 'string'
  ))) {
    fields.push('incoming_messages');
  }
  let failed = 0;
  if (Object.prototype.hasOwnProperty.call(body, 'simulate_failed_notifications')) {
    if (!isInt(body.simulate_failed_notifications) || body.simulate_failed_notifications < 0) {
      fields.push('simulate_failed_notifications');
    } else {
      failed = body.simulate_failed_notifications;
    }
  }
  if (fields.length > 0) return { ok: false, fields };
  return {
    ok: true,
    chat_room_id: body.chat_room_id,
    incoming_messages: body.incoming_messages,
    simulate_failed_notifications: failed,
  };
}

function moderateMessages(messages) {
  const seen = new Map();
  const filtered = [];
  const kicked = [];
  const muted = [];
  const kickedSet = new Set();
  const mutedSet = new Set();
  let flaggedCount = 0;

  function kick(sender) {
    if (kickedSet.has(sender)) return;
    kickedSet.add(sender);
    kicked.push(sender);
  }
  function mute(sender) {
    if (mutedSet.has(sender)) return;
    mutedSet.add(sender);
    muted.push(sender);
  }

  for (const message of messages) {
    const count = (seen.get(message.sender) || 0) + 1;
    seen.set(message.sender, count);
    if (count > 3) {
      flaggedCount += 1;
      kick(message.sender);
      mute(message.sender);
      continue;
    }
    if (isFlood(message.text)) {
      flaggedCount += 1;
      mute(message.sender);
      continue;
    }
    const masked = maskProfanity(message.text);
    if (masked.flagged) {
      flaggedCount += 1;
      kick(message.sender);
      filtered.push({
        message_id: message.message_id,
        sender: message.sender,
        text: masked.text,
        flagged: true,
        reason: 'profanity_leetspeak',
      });
      continue;
    }
    filtered.push({
      message_id: message.message_id,
      sender: message.sender,
      text: message.text,
      flagged: false,
      reason: null,
    });
  }

  return { filtered, kicked, muted, flaggedCount };
}

function buildModerationBody(chatRoomId, moderated, dlq) {
  const body = {
    chat_room_id: chatRoomId,
    filtered_messages: moderated.filtered,
    kicked_users: moderated.kicked,
    muted_users: moderated.muted,
    dlq_status: {
      queue_depth: dlq.queue_depth,
      undelivered_events: dlq.undelivered_events,
    },
  };
  body.signature = signDay2(day2Salt(), chatRoomId, {
    chat_room_id: chatRoomId,
    flagged_count: moderated.filtered.filter((message) => message.flagged).length,
    kicked_users: moderated.kicked,
    queue_depth: dlq.queue_depth,
  });
  return body;
}

async function handleModeration(pool, body) {
  const parsed = validateModeration(body);
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
  const moderated = moderateMessages(parsed.incoming_messages);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`dlq:${parsed.chat_room_id}`]);
    for (let index = 0; index < parsed.simulate_failed_notifications; index += 1) {
      await client.query(
        `INSERT INTO notification_dlq (chat_room_id, payload) VALUES ($1, $2::jsonb)`,
        [parsed.chat_room_id, JSON.stringify({
          reason: 'delivery_failed',
          chat_room_id: parsed.chat_room_id,
          sequence: index + 1,
        })],
      );
    }
    const depthRes = await client.query('SELECT COUNT(*)::int AS depth FROM notification_dlq');
    const eventsRes = await client.query('SELECT payload FROM notification_dlq ORDER BY id ASC');
    await client.query('COMMIT');
    return {
      status: 200,
      body: buildModerationBody(parsed.chat_room_id, moderated, {
        queue_depth: depthRes.rows[0].depth,
        undelivered_events: eventsRes.rows.map((row) => row.payload),
      }),
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  buildModerationBody,
  handleModeration,
  maskProfanity,
  moderateMessages,
  normalizeToken,
  validateModeration,
};
