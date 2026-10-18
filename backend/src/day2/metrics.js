async function renderMetrics(pool, wsConnections = 0) {
  const [streams, scans, dlq] = await Promise.all([
    pool.query(`SELECT COUNT(*)::int AS n FROM stream_keys WHERE status = 'active'`),
    pool.query('SELECT COALESCE(SUM(scan_count), 0)::int AS n FROM qr_links'),
    pool.query('SELECT COUNT(*)::int AS n FROM notification_dlq'),
  ]);
  return [
    '# TYPE nascon_active_ws_connections gauge',
    `nascon_active_ws_connections ${wsConnections}`,
    '# TYPE nascon_active_streams_total gauge',
    `nascon_active_streams_total ${streams.rows[0].n}`,
    '# TYPE nascon_stream_bitrate_kbps gauge',
    'nascon_stream_bitrate_kbps 0',
    '# TYPE nascon_dlq_depth gauge',
    `nascon_dlq_depth ${dlq.rows[0].n}`,
    '# TYPE nascon_qr_scans_total counter',
    `nascon_qr_scans_total ${scans.rows[0].n}`,
    '',
  ].join('\n');
}

module.exports = { renderMetrics };
