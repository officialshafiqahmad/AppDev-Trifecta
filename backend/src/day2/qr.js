const { projectMatch } = require('../scoring');
const { signDay2, day2Salt } = require('./sign');
const { qrPdf, qrPng, qrSvg } = require('./qr-image');

const NOTICE_STATES = new Set(['postponed', 'cancelled', 'abandoned']);
const EXPORTS = new Set(['svg', 'png', 'pdf']);

function targetRoute(entityType, entityId, status) {
  if (entityType === 'match') {
    if (status === 'upcoming') return `/web/matches/${entityId}/preview`;
    if (status === 'in_progress') return `/web/matches/${entityId}/live`;
    if (status === 'completed') return `/web/matches/${entityId}/vod`;
    if (NOTICE_STATES.has(status)) return `/web/matches/${entityId}/notice?state=${status}`;
    return `/web/matches/${entityId}/notice?state=${status}`;
  }
  if (entityType === 'player') return `/web/players/${entityId}`;
  if (entityType === 'club') return `/web/clubs/${entityId}`;
  if (entityType === 'costream') return `/web/costream/${entityId}`;
  return null;
}

function deviceFamily(userAgent) {
  if (/mobile|android|iphone|ipad|ipod/i.test(String(userAgent || ''))) return 'mobile';
  return 'desktop';
}

function hourBucket(now = new Date()) {
  const bucket = new Date(now);
  bucket.setUTCMinutes(0, 0, 0);
  return bucket.toISOString();
}

function scanTelemetry(userAgent, now = new Date()) {
  return {
    device_family: deviceFamily(userAgent),
    bucket: hourBucket(now),
  };
}

function notFound(entityId) {
  return {
    error: {
      status: 404,
      code: 'QR_NOT_FOUND',
      message: `QR mapping ${entityId} was not found.`,
      details: { entity_id: entityId },
    },
  };
}

async function matchStatus(client, matchId) {
  const matchRes = await client.query('SELECT * FROM matches WHERE match_id = $1', [matchId]);
  if (matchRes.rowCount === 0) return null;
  const match = matchRes.rows[0];
  const sportRes = await client.query('SELECT config FROM sports WHERE sport_id = $1', [match.sport_id]);
  const eventsRes = await client.query(
    'SELECT * FROM match_events WHERE match_id = $1 ORDER BY sequence ASC',
    [matchId],
  );
  const sportConfig = sportRes.rowCount ? sportRes.rows[0].config : { scoring_model: 'event', scoring_events: {} };
  return projectMatch(match, sportConfig, eventsRes.rows).status;
}

async function entityStatus(client, row) {
  if (row.entity_type === 'match') return (await matchStatus(client, row.entity_id)) || 'upcoming';
  if (row.entity_type === 'costream') {
    const session = await client.query(
      'SELECT status FROM costream_sessions WHERE session_id = $1',
      [row.entity_id],
    );
    return session.rowCount ? session.rows[0].status : 'active';
  }
  return 'active';
}

async function ensureQrLink(client, entityId) {
  const existing = await client.query('SELECT * FROM qr_links WHERE entity_id = $1', [entityId]);
  if (existing.rowCount === 1) return existing.rows[0];

  let entityType = null;
  const match = await client.query('SELECT match_id FROM matches WHERE match_id = $1', [entityId]);
  if (match.rowCount === 1) entityType = 'match';
  if (!entityType) {
    const player = await client.query('SELECT player_id FROM players WHERE player_id = $1', [entityId]);
    if (player.rowCount === 1) entityType = 'player';
  }
  if (!entityType) {
    const club = await client.query('SELECT club_id FROM clubs WHERE club_id = $1', [entityId]);
    if (club.rowCount === 1) entityType = 'club';
  }
  if (!entityType) {
    const session = await client.query(
      'SELECT session_id FROM costream_sessions WHERE session_id = $1',
      [entityId],
    );
    if (session.rowCount === 1) entityType = 'costream';
  }
  if (!entityType) return null;

  const shortCode = entityId;
  await client.query(
    `INSERT INTO qr_links (entity_id, entity_type, short_code, short_url, scan_count)
     VALUES ($1, $2, $3, $4, 0)
     ON CONFLICT (entity_id) DO NOTHING`,
    [entityId, entityType, shortCode, `http://localhost:8080/q/${shortCode}`],
  );
  const created = await client.query('SELECT * FROM qr_links WHERE entity_id = $1', [entityId]);
  return created.rows[0] || null;
}

function qrBody(row, status, scanCount) {
  const route = targetRoute(row.entity_type, row.entity_id, status);
  return {
    entity_id: row.entity_id,
    entity_type: row.entity_type,
    entity_status: status,
    short_url: row.short_url,
    target_route: route,
    deep_link_uri: `nascon://entity/${row.entity_id}`,
    scan_count: scanCount,
    export_formats: {
      svg: `http://localhost:8080/audit/v1/qr/${row.entity_id}/export.svg`,
      png: `http://localhost:8080/audit/v1/qr/${row.entity_id}/export.png`,
      pdf: `http://localhost:8080/audit/v1/qr/${row.entity_id}/export.pdf`,
    },
    signature: signDay2(day2Salt(), row.entity_id, {
      entity_id: row.entity_id,
      short_url: row.short_url,
      target_route: route,
    }),
  };
}

async function recordScan(client, row, userAgent) {
  const telemetry = scanTelemetry(userAgent);
  const updated = await client.query(
    `UPDATE qr_links SET scan_count = scan_count + 1 WHERE entity_id = $1 RETURNING scan_count`,
    [row.entity_id],
  );
  await client.query(
    `INSERT INTO qr_scan_buckets (entity_id, device_family, bucket, scan_count)
     VALUES ($1, $2, $3, 1)
     ON CONFLICT (entity_id, device_family, bucket)
     DO UPDATE SET scan_count = qr_scan_buckets.scan_count + 1`,
    [row.entity_id, telemetry.device_family, telemetry.bucket],
  );
  return updated.rows[0].scan_count;
}

async function inspectExistingQr(pool, entityId) {
  const client = await pool.connect();
  try {
    const existing = await client.query('SELECT * FROM qr_links WHERE entity_id = $1', [entityId]);
    if (existing.rowCount !== 1) return null;
    const row = existing.rows[0];
    const status = await entityStatus(client, row);
    return { status: 200, body: qrBody(row, status, row.scan_count) };
  } finally {
    client.release();
  }
}

async function resolveQr(pool, entityId, { inspect, userAgent }) {
  if (inspect) {
    const inspected = await inspectExistingQr(pool, entityId);
    if (inspected) return inspected;
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`qr:${entityId}`]);
    const row = await ensureQrLink(client, entityId);
    if (!row) {
      await client.query('ROLLBACK');
      return notFound(entityId);
    }
    const status = await entityStatus(client, row);
    const scanCount = inspect ? row.scan_count : await recordScan(client, row, userAgent);
    await client.query('COMMIT');
    return { status: 200, body: qrBody(row, status, scanCount) };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function resolveShortCode(pool, shortCode, userAgent) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`qr-short:${shortCode}`]);
    const found = await client.query('SELECT * FROM qr_links WHERE short_code = $1', [shortCode]);
    if (found.rowCount === 0) {
      await client.query('ROLLBACK');
      return {
        error: {
          status: 404,
          code: 'QR_NOT_FOUND',
          message: `QR short code ${shortCode} was not found.`,
          details: { short_code: shortCode },
        },
      };
    }
    const row = found.rows[0];
    const status = await entityStatus(client, row);
    await recordScan(client, row, userAgent);
    await client.query('COMMIT');
    return { status: 302, location: targetRoute(row.entity_type, row.entity_id, status) };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function exportQr(pool, entityId, format) {
  if (!EXPORTS.has(format)) {
    return {
      error: {
        status: 400,
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed.',
        details: { fields: ['format'] },
      },
    };
  }
  const rowRes = await pool.query('SELECT * FROM qr_links WHERE entity_id = $1', [entityId]);
  let row = rowRes.rows[0];
  if (!row) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      row = await ensureQrLink(client, entityId);
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
  if (!row) return notFound(entityId);

  if (format === 'svg') {
    return { status: 200, contentType: 'image/svg+xml', body: Buffer.from(qrSvg(row.short_url), 'utf8') };
  }
  if (format === 'png') {
    return { status: 200, contentType: 'image/png', body: qrPng(row.short_url) };
  }
  return { status: 200, contentType: 'application/pdf', body: qrPdf(row.short_url, row.entity_id) };
}

module.exports = {
  deviceFamily,
  exportQr,
  hourBucket,
  resolveQr,
  resolveShortCode,
  scanTelemetry,
  targetRoute,
};
