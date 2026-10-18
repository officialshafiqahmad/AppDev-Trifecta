const crypto = require('crypto');
const { signDay2, day2Salt } = require('./sign');

const ACTIONS = new Set(['generate', 'rotate', 'revoke']);
const GENERATED_KEY = /^sk_live_[a-f0-9]{16}$/;

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function validateStreamRequest(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ['body'] };
  const fields = [];
  if (typeof body.action !== 'string' || !ACTIONS.has(body.action)) fields.push('action');
  if (typeof body.player_id !== 'string' || body.player_id.length < 1) fields.push('player_id');

  let label = 'default';
  if (Object.prototype.hasOwnProperty.call(body, 'label')) {
    if (typeof body.label !== 'string' || body.label.length < 1 || body.label.length > 64) fields.push('label');
    else label = body.label;
  }

  let streamKeyOverride = null;
  if (Object.prototype.hasOwnProperty.call(body, 'stream_key_override')) {
    if (typeof body.stream_key_override !== 'string' || body.stream_key_override.length < 1) {
      fields.push('stream_key_override');
    } else {
      streamKeyOverride = body.stream_key_override;
    }
  }

  if (fields.length > 0) return { ok: false, fields };
  return {
    ok: true,
    action: body.action,
    player_id: body.player_id,
    label,
    stream_key_override: streamKeyOverride,
  };
}

function ingestEndpoints(streamKey) {
  return {
    rtmp: `rtmp://localhost:1935/live/${streamKey}`,
    webrtc: `http://localhost:8889/live/${streamKey}/whip`,
  };
}

function playbackUrl(streamKey) {
  return `http://localhost:8888/live/${streamKey}/index.m3u8`;
}

function buildStreamBody({ action, playerId, label, streamKey, status }) {
  const active = status === 'active';
  return {
    player_id: playerId,
    label,
    stream_key: streamKey,
    status,
    ingest_endpoints: active ? ingestEndpoints(streamKey) : null,
    playback_url: active ? playbackUrl(streamKey) : null,
    signature: signDay2(day2Salt(), streamKey, {
      action,
      player_id: playerId,
      status,
      stream_key: streamKey,
    }),
  };
}

function newStreamKey() {
  return `sk_live_${crypto.randomBytes(8).toString('hex')}`;
}

async function handleStreamKey(pool, body) {
  const parsed = validateStreamRequest(body);
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
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`stream:${parsed.player_id}`]);

    const player = await client.query('SELECT player_id FROM players WHERE player_id = $1', [parsed.player_id]);
    if (player.rowCount === 0) {
      await client.query('ROLLBACK');
      return {
        error: {
          status: 404,
          code: 'PLAYER_NOT_FOUND',
          message: `Player ${parsed.player_id} was not found.`,
          details: { player_id: parsed.player_id },
        },
      };
    }

    const active = await client.query(
      `SELECT stream_key, label FROM stream_keys
       WHERE player_id = $1 AND status = 'active'
       ORDER BY created_at DESC, stream_key DESC
       LIMIT 1`,
      [parsed.player_id],
    );

    if (parsed.action === 'revoke') {
      if (active.rowCount === 0) {
        await client.query('ROLLBACK');
        return {
          error: {
            status: 404,
            code: 'STREAM_NOT_FOUND',
            message: `No active stream key for ${parsed.player_id}.`,
            details: { player_id: parsed.player_id },
          },
        };
      }
      const current = active.rows[0];
      await client.query(`UPDATE stream_keys SET status = 'revoked' WHERE stream_key = $1`, [current.stream_key]);
      await client.query('COMMIT');
      return {
        status: 200,
        body: buildStreamBody({
          action: 'revoke',
          playerId: parsed.player_id,
          label: current.label,
          streamKey: current.stream_key,
          status: 'revoked',
        }),
      };
    }

    const streamKey = parsed.stream_key_override || newStreamKey();
    const existing = await client.query('SELECT stream_key, status FROM stream_keys WHERE stream_key = $1', [streamKey]);
    if (existing.rowCount === 1 && existing.rows[0].status === 'revoked') {
      await client.query('ROLLBACK');
      return {
        error: {
          status: 409,
          code: 'KEY_REVOKED',
          message: 'Stream key has been revoked.',
          details: { stream_key: streamKey },
        },
      };
    }

    await client.query(
      `UPDATE stream_keys SET status = 'revoked' WHERE player_id = $1 AND status = 'active'`,
      [parsed.player_id],
    );

    if (existing.rowCount === 0) {
      await client.query(
        `INSERT INTO stream_keys (stream_key, player_id, label, status)
         VALUES ($1, $2, $3, 'active')`,
        [streamKey, parsed.player_id, parsed.label],
      );
    } else {
      await client.query(
        `UPDATE stream_keys SET player_id = $1, label = $2, status = 'active' WHERE stream_key = $3`,
        [parsed.player_id, parsed.label, streamKey],
      );
    }

    await client.query('COMMIT');
    return {
      status: parsed.action === 'generate' ? 201 : 200,
      body: buildStreamBody({
        action: parsed.action,
        playerId: parsed.player_id,
        label: parsed.label,
        streamKey,
        status: 'active',
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
  GENERATED_KEY,
  buildStreamBody,
  handleStreamKey,
  ingestEndpoints,
  newStreamKey,
  playbackUrl,
  validateStreamRequest,
};
