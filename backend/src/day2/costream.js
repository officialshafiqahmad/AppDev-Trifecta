const crypto = require('crypto');
const { canonical } = require('../canonical');
const { signDay2, day2Salt } = require('./sign');

const LAYOUTS = new Set(['solo', 'grid_2', 'grid_4', 'spotlight']);

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function validateCostreamRequest(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ['body'] };
  const fields = [];
  if (typeof body.session_id !== 'string' || body.session_id.length < 1) fields.push('session_id');
  if (typeof body.host_player_id !== 'string' || body.host_player_id.length < 1) fields.push('host_player_id');

  const participants = body.participants;
  if (!Array.isArray(participants) || participants.length < 1
    || participants.some((id) => typeof id !== 'string' || id.length < 1)
    || new Set(participants).size !== participants.length) {
    fields.push('participants');
  }

  let simulateHostDrop = false;
  if (Object.prototype.hasOwnProperty.call(body, 'simulate_host_drop')) {
    if (typeof body.simulate_host_drop !== 'boolean') fields.push('simulate_host_drop');
    else simulateHostDrop = body.simulate_host_drop;
  }

  let layout = 'grid_4';
  if (Object.prototype.hasOwnProperty.call(body, 'layout')) {
    if (typeof body.layout !== 'string' || !LAYOUTS.has(body.layout)) fields.push('layout');
    else layout = body.layout;
  }

  if (fields.length > 0) return { ok: false, fields };
  return {
    ok: true,
    session_id: body.session_id,
    host_player_id: body.host_player_id,
    participants: participants.slice(),
    layout,
    simulate_host_drop: simulateHostDrop,
  };
}

function layoutFits(layout, participantCount) {
  if (layout === 'solo') return participantCount <= 1;
  if (layout === 'grid_2') return participantCount <= 2;
  return true;
}

function resolveHandoff(request) {
  if (!request.simulate_host_drop) {
    return {
      active_host: request.host_player_id,
      handoff_occurred: false,
      participant_count: request.participants.length,
      active_participants: request.participants.slice(),
      status: 'active',
    };
  }
  if (request.participants.length >= 2) {
    const activeParticipants = request.participants.filter((id) => id !== request.host_player_id);
    return {
      active_host: activeParticipants[0],
      handoff_occurred: true,
      participant_count: activeParticipants.length,
      active_participants: activeParticipants,
      status: 'active',
    };
  }
  return {
    active_host: null,
    handoff_occurred: false,
    participant_count: 0,
    active_participants: [],
    status: 'terminated',
  };
}

function evaluateCostream(request, knownPlayerIds) {
  const known = knownPlayerIds instanceof Set ? knownPlayerIds : new Set(knownPlayerIds);
  for (const playerId of request.participants) {
    if (!known.has(playerId)) {
      return {
        error: {
          status: 404,
          code: 'PLAYER_NOT_FOUND',
          message: `Player ${playerId} was not found.`,
          details: { player_id: playerId },
        },
      };
    }
  }
  if (!known.has(request.host_player_id)) {
    return {
      error: {
        status: 404,
        code: 'PLAYER_NOT_FOUND',
        message: `Player ${request.host_player_id} was not found.`,
        details: { player_id: request.host_player_id },
      },
    };
  }
  if (!request.participants.includes(request.host_player_id)) {
    return {
      error: {
        status: 400,
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed.',
        details: { fields: ['host_player_id'] },
      },
    };
  }
  if (request.participants.length > 4) {
    return {
      error: {
        status: 409,
        code: 'COSTREAM_SESSION_FULL',
        message: 'Co-stream sessions support at most 4 participants.',
        details: { participant_count: request.participants.length },
      },
    };
  }
  if (!layoutFits(request.layout, request.participants.length)) {
    return {
      error: {
        status: 400,
        code: 'UNSUPPORTED_LAYOUT',
        message: 'Requested layout cannot fit the active participant count.',
        details: { layout: request.layout, participant_count: request.participants.length },
      },
    };
  }
  return { ok: true, outcome: resolveHandoff(request) };
}

function costreamHash(request) {
  return crypto.createHash('sha256').update(canonical({
    session_id: request.session_id,
    host_player_id: request.host_player_id,
    participants: request.participants,
    layout: request.layout,
    simulate_host_drop: request.simulate_host_drop,
  })).digest('hex');
}

function buildCostreamBody(request, outcome) {
  const body = {
    session_id: request.session_id,
    status: outcome.status,
    active_host: outcome.active_host,
    handoff_occurred: outcome.handoff_occurred,
    participant_count: outcome.participant_count,
    active_participants: outcome.active_participants,
    layout: request.layout,
    composite_playback_url: `http://localhost:8888/costream/${request.session_id}/index.m3u8`,
    chat_room_id: `chat-${request.session_id}`,
  };
  body.signature = signDay2(day2Salt(), request.session_id, {
    active_host: body.active_host,
    handoff_occurred: body.handoff_occurred,
    layout: body.layout,
    participant_count: body.participant_count,
    session_id: body.session_id,
    status: body.status,
  });
  return body;
}

async function handleCostream(pool, body) {
  const parsed = validateCostreamRequest(body);
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
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`costream:${parsed.session_id}`]);

    const hash = costreamHash(parsed);
    const existing = await client.query(
      'SELECT request_hash, response FROM costream_sessions WHERE session_id = $1',
      [parsed.session_id],
    );
    if (existing.rowCount === 1) {
      if (existing.rows[0].request_hash === hash) {
        await client.query('COMMIT');
        return { status: 200, body: existing.rows[0].response };
      }
      await client.query('ROLLBACK');
      return {
        error: {
          status: 409,
          code: 'SESSION_EXISTS',
          message: 'Co-stream session already exists with a different request.',
          details: { session_id: parsed.session_id },
        },
      };
    }

    const ids = [...new Set([...parsed.participants, parsed.host_player_id])];
    const found = await client.query(
      'SELECT player_id FROM players WHERE player_id = ANY($1::text[])',
      [ids],
    );
    const decision = evaluateCostream(parsed, found.rows.map((row) => row.player_id));
    if (decision.error) {
      await client.query('ROLLBACK');
      return { error: decision.error };
    }

    const response = buildCostreamBody(parsed, decision.outcome);
    await client.query(
      `INSERT INTO costream_sessions
        (session_id, request_hash, response, status, active_host, layout, chat_room_id)
       VALUES ($1, $2, $3::jsonb, $4, $5, $6, $7)`,
      [
        parsed.session_id,
        hash,
        JSON.stringify(response),
        response.status,
        response.active_host,
        response.layout,
        response.chat_room_id,
      ],
    );
    await client.query(
      `INSERT INTO qr_links (entity_id, entity_type, short_code, short_url, scan_count)
       VALUES ($1, 'costream', $2, $3, 0)
       ON CONFLICT (entity_id) DO NOTHING`,
      [parsed.session_id, parsed.session_id, `http://localhost:8080/q/${parsed.session_id}`],
    );
    await client.query('COMMIT');
    return { status: 201, body: response };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  buildCostreamBody,
  costreamHash,
  evaluateCostream,
  handleCostream,
  resolveHandoff,
  validateCostreamRequest,
};
