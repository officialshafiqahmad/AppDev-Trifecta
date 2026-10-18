const { describe, it, before } = require('node:test');
const assert = require('node:assert/strict');
const { signDay2 } = require('../src/day2/sign');

const BASE = process.env.AUDIT_BASE_URL || 'http://127.0.0.1:8080';
const DAY2 = process.env.DAY2_SALT;

async function request(method, path, body, headers = {}) {
  const options = { method, headers: { ...headers }, redirect: 'manual' };
  if (body !== undefined) {
    options.headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  const buffer = Buffer.from(await res.arrayBuffer());
  const type = res.headers.get('content-type') || '';
  let json = null;
  if (type.includes('json') || type.includes('text')) {
    const text = buffer.toString('utf8');
    try {
      json = JSON.parse(text);
    } catch (_err) {
      json = text;
    }
  }
  return {
    status: res.status,
    json,
    buffer,
    type,
    location: res.headers.get('location'),
  };
}

describe('Phase II stream, co-stream, and QR HTTP', { skip: process.env.SKIP_HTTP === '1' }, () => {
  before(async () => {
    assert.equal(typeof DAY2, 'string');
    assert.ok(DAY2.length > 0, 'DAY2_SALT must be set for signature checks');
    const health = await request('GET', '/health');
    if (health.status !== 200) throw new Error('API not ready');
    const reset = await request('POST', '/audit/v1/reset', {});
    assert.equal(reset.status, 200);
    assert.equal(reset.json.status, 'reset_complete');
  });

  it('rotates, regenerates, and revokes a signed stream key', async () => {
    const rotated = await request('POST', '/audit/v1/stream/key', {
      action: 'rotate',
      player_id: 'player-alpha-1',
      label: 'OBS-Main-Desk',
      stream_key_override: 'sk_live_9f83a1b2c3d4e5f6',
    });
    assert.equal(rotated.status, 200);
    assert.equal(rotated.json.stream_key, 'sk_live_9f83a1b2c3d4e5f6');
    assert.equal(rotated.json.status, 'active');
    assert.equal(rotated.json.ingest_endpoints.webrtc, 'http://localhost:8889/live/sk_live_9f83a1b2c3d4e5f6/whip');
    assert.equal(rotated.json.signature, signDay2(DAY2, rotated.json.stream_key, {
      action: 'rotate',
      player_id: 'player-alpha-1',
      status: 'active',
      stream_key: rotated.json.stream_key,
    }));

    const generated = await request('POST', '/audit/v1/stream/key', {
      action: 'generate',
      player_id: 'player-alpha-1',
    });
    assert.equal(generated.status, 201);
    assert.match(generated.json.stream_key, /^sk_live_[a-f0-9]{16}$/);
    assert.notEqual(generated.json.stream_key, 'sk_live_9f83a1b2c3d4e5f6');

    const reused = await request('POST', '/audit/v1/stream/key', {
      action: 'rotate',
      player_id: 'player-alpha-1',
      stream_key_override: 'sk_live_9f83a1b2c3d4e5f6',
    });
    assert.equal(reused.status, 409);
    assert.equal(reused.json.error.code, 'KEY_REVOKED');

    const revoked = await request('POST', '/audit/v1/stream/key', {
      action: 'revoke',
      player_id: 'player-alpha-1',
    });
    assert.equal(revoked.status, 200);
    assert.equal(revoked.json.stream_key, generated.json.stream_key);
    assert.equal(revoked.json.status, 'revoked');
    assert.equal(revoked.json.ingest_endpoints, null);
    assert.equal(revoked.json.playback_url, null);

    const again = await request('POST', '/audit/v1/stream/key', {
      action: 'revoke',
      player_id: 'player-alpha-1',
    });
    assert.equal(again.status, 404);
    assert.equal(again.json.error.code, 'STREAM_NOT_FOUND');

    const missing = await request('POST', '/audit/v1/stream/key', {
      action: 'generate',
      player_id: 'player-missing',
    });
    assert.equal(missing.status, 404);
    assert.equal(missing.json.error.code, 'PLAYER_NOT_FOUND');

    const invalid = await request('POST', '/audit/v1/stream/key', { action: 'pause' });
    assert.equal(invalid.status, 400);
    assert.equal(invalid.json.error.code, 'VALIDATION_ERROR');
    assert.ok(invalid.json.error.details.fields.includes('action'));
    assert.ok(invalid.json.error.details.fields.includes('player_id'));
  });

  it('creates a co-stream, hands off the host, and replays the same request', async () => {
    const payload = {
      session_id: 'cs-session-101',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1', 'player-alpha-2', 'player-beta-1', 'player-beta-2'],
      layout: 'grid_4',
      simulate_host_drop: true,
    };
    const created = await request('POST', '/audit/v1/costream/session', payload);
    assert.equal(created.status, 201);
    assert.equal(created.json.active_host, 'player-alpha-2');
    assert.equal(created.json.handoff_occurred, true);
    assert.equal(created.json.participant_count, 3);
    assert.deepEqual(created.json.active_participants, ['player-alpha-2', 'player-beta-1', 'player-beta-2']);
    assert.equal(created.json.chat_room_id, 'chat-cs-session-101');
    assert.equal(created.json.signature, signDay2(DAY2, 'cs-session-101', {
      active_host: 'player-alpha-2',
      handoff_occurred: true,
      layout: 'grid_4',
      participant_count: 3,
      session_id: 'cs-session-101',
      status: 'active',
    }));

    const replay = await request('POST', '/audit/v1/costream/session', payload);
    assert.equal(replay.status, 200);
    assert.deepEqual(replay.json, created.json);

    const solo = await request('POST', '/audit/v1/costream/session', {
      session_id: 'cs-session-solo',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1', 'player-alpha-2'],
      layout: 'solo',
    });
    assert.equal(solo.status, 400);
    assert.equal(solo.json.error.code, 'UNSUPPORTED_LAYOUT');

    const ended = await request('POST', '/audit/v1/costream/session', {
      session_id: 'cs-session-end',
      host_player_id: 'player-beta-2',
      participants: ['player-beta-2'],
      layout: 'solo',
      simulate_host_drop: true,
    });
    assert.equal(ended.status, 201);
    assert.equal(ended.json.status, 'terminated');
    assert.equal(ended.json.active_host, null);
    assert.equal(ended.json.participant_count, 0);
    assert.equal(ended.json.handoff_occurred, false);
  });

  it('resolves match-m1, redirects /q/m1-live, and exports QR artifacts', async () => {
    const inspected = await request('GET', '/audit/v1/qr/match-m1?inspect=true');
    assert.equal(inspected.status, 200);
    assert.equal(inspected.json.scan_count, 0);
    assert.equal(inspected.json.short_url, 'http://localhost:8080/q/m1-live');
    assert.equal(inspected.json.target_route, '/web/matches/match-m1/live');
    assert.equal(inspected.json.entity_status, 'in_progress');
    assert.equal(inspected.json.deep_link_uri, 'nascon://entity/match-m1');
    assert.equal(inspected.json.signature, signDay2(DAY2, 'match-m1', {
      entity_id: 'match-m1',
      short_url: inspected.json.short_url,
      target_route: inspected.json.target_route,
    }));

    const scanned = await request('GET', '/audit/v1/qr/match-m1', undefined, {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
    });
    assert.equal(scanned.status, 200);
    assert.equal(scanned.json.scan_count, 1);
    assert.equal(scanned.json.short_url, inspected.json.short_url);

    const redirect = await request('GET', '/q/m1-live');
    assert.equal(redirect.status, 302);
    assert.equal(redirect.location, '/web/matches/match-m1/live');

    const afterRedirect = await request('GET', '/audit/v1/qr/match-m1?inspect=true');
    assert.equal(afterRedirect.json.scan_count, 2);

    const svg = await request('GET', '/audit/v1/qr/match-m1/export.svg');
    assert.equal(svg.status, 200);
    assert.equal(svg.type, 'image/svg+xml');
    assert.equal(svg.buffer.subarray(0, 5).toString('utf8'), '<?xml');
    assert.match(svg.buffer.toString('utf8'), /http:\/\/localhost:8080\/q\/m1-live/);

    const png = await request('GET', '/audit/v1/qr/match-m1/export.png');
    assert.equal(png.status, 200);
    assert.equal(png.type, 'image/png');
    assert.deepEqual([...png.buffer.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);

    const pdf = await request('GET', '/audit/v1/qr/match-m1/export.pdf');
    assert.equal(pdf.status, 200);
    assert.equal(pdf.type, 'application/pdf');
    assert.equal(pdf.buffer.subarray(0, 5).toString('utf8'), '%PDF-');
    assert.match(pdf.buffer.toString('utf8'), /match-m1/);

    const missing = await request('GET', '/audit/v1/qr/no-such-entity');
    assert.equal(missing.status, 404);
    assert.equal(missing.json.error.code, 'QR_NOT_FOUND');
  });

  it('keeps the short URL and updates the target after match_end', async () => {
    const ended = await request('POST', '/audit/v1/events', {
      event_id: 'match-m1-end',
      match_id: 'match-m1',
      type: 'match_end',
      payload: {},
    });
    assert.equal(ended.status, 201);
    const vod = await request('GET', '/audit/v1/qr/match-m1?inspect=true');
    assert.equal(vod.json.short_url, 'http://localhost:8080/q/m1-live');
    assert.equal(vod.json.entity_status, 'completed');
    assert.equal(vod.json.target_route, '/web/matches/match-m1/vod');
    assert.equal(vod.json.signature, signDay2(DAY2, 'match-m1', {
      entity_id: 'match-m1',
      short_url: 'http://localhost:8080/q/m1-live',
      target_route: '/web/matches/match-m1/vod',
    }));
    const redirect = await request('GET', '/q/m1-live');
    assert.equal(redirect.location, '/web/matches/match-m1/vod');
  });
});
