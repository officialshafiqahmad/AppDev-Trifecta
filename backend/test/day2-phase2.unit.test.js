const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { signDay2 } = require('../src/day2/sign');
const {
  GENERATED_KEY,
  buildStreamBody,
  newStreamKey,
  validateStreamRequest,
} = require('../src/day2/stream-key');
const {
  buildCostreamBody,
  evaluateCostream,
  resolveHandoff,
  validateCostreamRequest,
} = require('../src/day2/costream');
const { qrPdf, qrPng, qrSvg } = require('../src/day2/qr-image');
const { deviceFamily, scanTelemetry, targetRoute } = require('../src/day2/qr');

const SALT = 'T01D27ad7ffff12e';
const PLAYERS = ['player-alpha-1', 'player-alpha-2', 'player-beta-1', 'player-beta-2', 'player-extra'];

describe('stream key contract', () => {
  let previous;
  beforeEach(() => {
    previous = process.env.DAY2_SALT;
    process.env.DAY2_SALT = SALT;
  });
  afterEach(() => {
    if (previous === undefined) delete process.env.DAY2_SALT;
    else process.env.DAY2_SALT = previous;
  });

  it('rejects a bad action and defaults the label', () => {
    assert.deepEqual(validateStreamRequest({ action: 'drop', player_id: 'player-alpha-1' }).fields, ['action']);
    const parsed = validateStreamRequest({ action: 'rotate', player_id: 'player-alpha-1' });
    assert.equal(parsed.label, 'default');
    assert.equal(parsed.stream_key_override, null);
  });

  it('signs the Section 5.3 stream payload', () => {
    const body = buildStreamBody({
      action: 'rotate',
      playerId: 'player-alpha-1',
      label: 'OBS-Main-Desk',
      streamKey: 'sk_live_9f83a1b2c3d4e5f6',
      status: 'active',
    });
    assert.equal(body.status, 'active');
    assert.equal(body.ingest_endpoints.rtmp, 'rtmp://localhost:1935/live/sk_live_9f83a1b2c3d4e5f6');
    assert.equal(body.playback_url, 'http://localhost:8888/live/sk_live_9f83a1b2c3d4e5f6/index.m3u8');
    assert.equal(body.signature, '9bd054eb746844b4701c6f158209c315ef2b16f392efd733bdf0715940610289');
  });

  it('nulls ingest endpoints when revoked', () => {
    const body = buildStreamBody({
      action: 'revoke',
      playerId: 'player-alpha-1',
      label: 'default',
      streamKey: 'sk_live_9f83a1b2c3d4e5f6',
      status: 'revoked',
    });
    assert.equal(body.ingest_endpoints, null);
    assert.equal(body.playback_url, null);
    assert.equal(body.signature, signDay2(SALT, body.stream_key, {
      action: 'revoke',
      player_id: 'player-alpha-1',
      status: 'revoked',
      stream_key: body.stream_key,
    }));
  });

  it('generates a 16-hex stream key', () => {
    assert.match(newStreamKey(), GENERATED_KEY);
  });
});

describe('co-stream handoff', () => {
  const request = {
    session_id: 'cs-session-101',
    host_player_id: 'player-alpha-1',
    participants: ['player-alpha-1', 'player-alpha-2', 'player-beta-1', 'player-beta-2'],
    layout: 'grid_4',
    simulate_host_drop: true,
  };

  let previous;
  beforeEach(() => {
    previous = process.env.DAY2_SALT;
    process.env.DAY2_SALT = SALT;
  });
  afterEach(() => {
    if (previous === undefined) delete process.env.DAY2_SALT;
    else process.env.DAY2_SALT = previous;
  });

  it('promotes the next participant when the host drops', () => {
    const decision = evaluateCostream(request, PLAYERS);
    assert.equal(decision.ok, true);
    assert.equal(decision.outcome.active_host, 'player-alpha-2');
    assert.equal(decision.outcome.handoff_occurred, true);
    assert.equal(decision.outcome.participant_count, 3);
    assert.deepEqual(decision.outcome.active_participants, ['player-alpha-2', 'player-beta-1', 'player-beta-2']);
  });

  it('keeps the host when no drop is requested', () => {
    const outcome = resolveHandoff({ ...request, simulate_host_drop: false });
    assert.equal(outcome.active_host, 'player-alpha-1');
    assert.equal(outcome.handoff_occurred, false);
    assert.equal(outcome.participant_count, 4);
  });

  it('terminates a sole host drop', () => {
    const outcome = resolveHandoff({
      ...request,
      participants: ['player-alpha-1'],
      layout: 'solo',
      simulate_host_drop: true,
    });
    assert.equal(outcome.status, 'terminated');
    assert.equal(outcome.active_host, null);
    assert.equal(outcome.handoff_occurred, false);
    assert.equal(outcome.participant_count, 0);
  });

  it('checks existence before capacity and layout', () => {
    const missing = evaluateCostream({
      ...request,
      participants: ['missing-player', 'player-alpha-2', 'player-beta-1', 'player-beta-2', 'player-extra'],
    }, PLAYERS);
    assert.equal(missing.error.status, 404);
    assert.equal(missing.error.code, 'PLAYER_NOT_FOUND');

    const full = evaluateCostream({
      ...request,
      host_player_id: 'player-alpha-1',
      participants: PLAYERS,
    }, PLAYERS);
    assert.equal(full.error.status, 409);
    assert.equal(full.error.code, 'COSTREAM_SESSION_FULL');

    const layout = evaluateCostream({ ...request, layout: 'solo', simulate_host_drop: false }, PLAYERS);
    assert.equal(layout.error.status, 400);
    assert.equal(layout.error.code, 'UNSUPPORTED_LAYOUT');

    const outsider = evaluateCostream({
      ...request,
      host_player_id: 'player-extra',
      simulate_host_drop: false,
    }, PLAYERS);
    assert.equal(outsider.error.status, 400);
    assert.deepEqual(outsider.error.details.fields, ['host_player_id']);
  });

  it('defaults layout and rejects duplicate participants', () => {
    const parsed = validateCostreamRequest({
      session_id: 'cs-session-101',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1'],
    });
    assert.equal(parsed.layout, 'grid_4');
    assert.equal(parsed.simulate_host_drop, false);
    assert.ok(validateCostreamRequest({
      session_id: 'cs-session-101',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1', 'player-alpha-1'],
    }).fields.includes('participants'));
  });

  it('signs the Section 5.3 co-stream payload', () => {
    const body = buildCostreamBody(request, evaluateCostream(request, PLAYERS).outcome);
    assert.equal(body.chat_room_id, 'chat-cs-session-101');
    assert.equal(body.composite_playback_url, 'http://localhost:8888/costream/cs-session-101/index.m3u8');
    assert.equal(body.signature, signDay2(SALT, 'cs-session-101', {
      active_host: 'player-alpha-2',
      handoff_occurred: true,
      layout: 'grid_4',
      participant_count: 3,
      session_id: 'cs-session-101',
      status: 'active',
    }));
  });
});

describe('dynamic QR routes and exports', () => {
  it('maps match, player, club, and co-stream targets', () => {
    assert.equal(targetRoute('match', 'match-m1', 'upcoming'), '/web/matches/match-m1/preview');
    assert.equal(targetRoute('match', 'match-m1', 'in_progress'), '/web/matches/match-m1/live');
    assert.equal(targetRoute('match', 'match-m1', 'completed'), '/web/matches/match-m1/vod');
    assert.equal(targetRoute('match', 'match-m1', 'postponed'), '/web/matches/match-m1/notice?state=postponed');
    assert.equal(targetRoute('match', 'match-m1', 'cancelled'), '/web/matches/match-m1/notice?state=cancelled');
    assert.equal(targetRoute('match', 'match-m1', 'abandoned'), '/web/matches/match-m1/notice?state=abandoned');
    assert.equal(targetRoute('player', 'player-alpha-1', 'active'), '/web/players/player-alpha-1');
    assert.equal(targetRoute('club', 'club-alpha-1', 'active'), '/web/clubs/club-alpha-1');
    assert.equal(targetRoute('costream', 'cs-session-101', 'active'), '/web/costream/cs-session-101');
  });

  it('stores device family and an hour bucket without the raw user agent', () => {
    const telemetry = scanTelemetry('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)', new Date('2026-10-18T06:40:22.000Z'));
    assert.equal(telemetry.device_family, 'mobile');
    assert.equal(telemetry.bucket, '2026-10-18T06:00:00.000Z');
    assert.equal(deviceFamily('Mozilla/5.0 (X11; Linux x86_64)'), 'desktop');
    assert.equal(Object.hasOwn(telemetry, 'user_agent'), false);
    assert.equal(Object.hasOwn(telemetry, 'ip'), false);
  });

  it('exports SVG, PNG, and PDF that carry the short URL and entity', () => {
    const shortUrl = 'http://localhost:8080/q/m1-live';
    const svg = qrSvg(shortUrl);
    assert.equal(svg.startsWith('<?xml'), true);
    assert.match(svg, /<svg/);
    assert.match(svg, /http:\/\/localhost:8080\/q\/m1-live/);
    const png = qrPng(shortUrl);
    assert.deepEqual([...png.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
    const pdf = qrPdf(shortUrl, 'match-m1');
    assert.equal(pdf.subarray(0, 5).toString('utf8'), '%PDF-');
    assert.match(pdf.toString('utf8'), /match-m1/);
  });
});
