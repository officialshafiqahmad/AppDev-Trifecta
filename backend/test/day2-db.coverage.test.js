const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');

const enabled = Boolean(process.env.DATABASE_URL && process.env.DAY1_SALT && process.env.DAY2_SALT);

async function request(base, method, path, body, headers = {}) {
  const options = { method, headers: { ...headers }, redirect: 'manual' };
  if (body !== undefined) {
    options.headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${base}${path}`, options);
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_err) {
    json = null;
  }
  return { status: res.status, json, text, type: res.headers.get('content-type') };
}

describe('Day 2 database-backed handlers', { skip: enabled ? false : 'DATABASE_URL is not set' }, () => {
  let server;
  let base;
  let pool;

  before(async () => {
    const { createPool } = require('../src/db');
    const { applyReset, DEFAULT_STOCK } = require('../src/baseline');
    const { createApp } = require('../src/app');
    pool = createPool();
    await applyReset(pool, { seed: 42, stock: { ...DEFAULT_STOCK } });
    const app = createApp(pool);
    await new Promise((resolve) => {
      server = app.listen(0, '127.0.0.1', resolve);
    });
    base = `http://127.0.0.1:${server.address().port}`;
  });

  after(async () => {
    if (server) await new Promise((resolve) => server.close(resolve));
    if (pool) await pool.end();
  });

  it('covers stream key generate, rotate, revoke, and rejection paths', async () => {
    const bad = await request(base, 'POST', '/audit/v1/stream/key', { action: 'nope' });
    assert.equal(bad.status, 400);
    const missing = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'generate',
      player_id: 'player-missing',
    });
    assert.equal(missing.status, 404);

    const generated = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'generate',
      player_id: 'player-alpha-1',
      label: 'desk',
    });
    assert.equal(generated.status, 201);
    assert.match(generated.json.stream_key, /^sk_live_[a-f0-9]{16}$/);

    const rotated = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'rotate',
      player_id: 'player-alpha-1',
      stream_key_override: 'sk_live_covoverride01',
    });
    assert.equal(rotated.status, 200);
    assert.equal(rotated.json.status, 'active');

    const revoked = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'revoke',
      player_id: 'player-alpha-1',
    });
    assert.equal(revoked.status, 200);
    assert.equal(revoked.json.status, 'revoked');
    assert.equal(revoked.json.playback_url, null);

    const again = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'rotate',
      player_id: 'player-alpha-1',
      stream_key_override: 'sk_live_covoverride01',
    });
    assert.equal(again.status, 409);
    assert.equal(again.json.error.code, 'KEY_REVOKED');

    const noKey = await request(base, 'POST', '/audit/v1/stream/key', {
      action: 'revoke',
      player_id: 'player-beta-2',
    });
    assert.equal(noKey.status, 404);
  });

  it('covers co-stream handoff, capacity, layout, and replay', async () => {
    const players = ['player-alpha-1', 'player-alpha-2', 'player-beta-1', 'player-beta-2'];
    const body = {
      session_id: 'cs-coverage-1',
      host_player_id: 'player-alpha-1',
      participants: players,
      layout: 'grid_4',
      simulate_host_drop: true,
    };
    const created = await request(base, 'POST', '/audit/v1/costream/session', body);
    assert.equal(created.status, 201);
    assert.equal(created.json.handoff_occurred, true);
    assert.equal(created.json.active_host, 'player-alpha-2');

    const replay = await request(base, 'POST', '/audit/v1/costream/session', body);
    assert.equal(replay.status, 200);
    assert.equal(replay.json.signature, created.json.signature);

    await pool.query(
      `INSERT INTO players (player_id, club_id, name) VALUES ('player-extra', 'club-alpha-1', 'Extra')`,
    );
    const full = await request(base, 'POST', '/audit/v1/costream/session', {
      ...body,
      session_id: 'cs-coverage-full',
      participants: [...players, 'player-extra'],
    });
    assert.equal(full.status, 409);
    assert.equal(full.json.error.code, 'COSTREAM_SESSION_FULL');

    const layout = await request(base, 'POST', '/audit/v1/costream/session', {
      session_id: 'cs-coverage-solo',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1', 'player-alpha-2'],
      layout: 'solo',
      simulate_host_drop: false,
    });
    assert.equal(layout.status, 400);
    assert.equal(layout.json.error.code, 'UNSUPPORTED_LAYOUT');

    const ended = await request(base, 'POST', '/audit/v1/costream/session', {
      session_id: 'cs-coverage-end',
      host_player_id: 'player-alpha-1',
      participants: ['player-alpha-1'],
      simulate_host_drop: true,
    });
    assert.equal(ended.status, 201);
    assert.equal(ended.json.status, 'terminated');
    assert.equal(ended.json.active_host, null);

    const absent = await request(base, 'POST', '/audit/v1/costream/session', {
      session_id: 'cs-coverage-missing',
      host_player_id: 'player-missing',
      participants: ['player-missing'],
    });
    assert.equal(absent.status, 404);
    const notHost = await request(base, 'POST', '/audit/v1/costream/session', {
      session_id: 'cs-coverage-host',
      host_player_id: 'player-beta-1',
      participants: ['player-alpha-1'],
    });
    assert.equal(notHost.status, 400);
    const changed = await request(base, 'POST', '/audit/v1/costream/session', {
      ...body,
      layout: 'spotlight',
    });
    assert.equal(changed.status, 409);
    assert.equal(changed.json.error.code, 'SESSION_EXISTS');
    const malformed = await request(base, 'POST', '/audit/v1/costream/session', {});
    assert.equal(malformed.status, 400);
  });

  it('covers QR inspect, scan, export, and a missing id', async () => {
    const inspected = await request(base, 'GET', '/audit/v1/qr/match-m1?inspect=true');
    assert.equal(inspected.status, 200);
    assert.equal(inspected.json.scan_count, 0);
    assert.equal(inspected.json.target_route, '/web/matches/match-m1/live');

    const scanned = await request(base, 'GET', '/audit/v1/qr/match-m1');
    assert.equal(scanned.json.scan_count, 1);
    const svg = await request(base, 'GET', '/audit/v1/qr/match-m1/export.svg');
    assert.equal(svg.status, 200);
    assert.match(svg.text, /<svg|<\?xml/);
    const missing = await request(base, 'GET', '/audit/v1/qr/does-not-exist');
    assert.equal(missing.status, 404);
    assert.equal(missing.json.error.code, 'QR_NOT_FOUND');

    const png = await request(base, 'GET', '/audit/v1/qr/player-alpha-1/export.png');
    assert.equal(png.status, 200);
    const pdf = await request(base, 'GET', '/audit/v1/qr/club-alpha-1/export.pdf');
    assert.equal(pdf.status, 200);
    const badFormat = await request(base, 'GET', '/audit/v1/qr/match-m1/export.gif');
    assert.equal(badFormat.status, 400);
    const redirect = await request(base, 'GET', '/q/m1-live');
    assert.equal(redirect.status, 302);
    const missingShort = await request(base, 'GET', '/q/missing-code');
    assert.equal(missingShort.status, 404);
  });

  it('covers moderation, an empty DLQ read, and a failed-notification write', async () => {
    const moderated = await request(base, 'POST', '/audit/v1/moderation/test', {
      chat_room_id: 'chat-coverage',
      incoming_messages: [
        { message_id: 'm1', sender: 'user-guest-1', text: 'Clean sports commentary' },
        { message_id: 'm2', sender: 'user-spammer', text: 'Watch this illegal stream b@d_w0rd now!' },
        { message_id: 'm3', sender: 'user-flooder', text: 'GOAL! AAAA!!!' },
      ],
      check_dlq: true,
    });
    assert.equal(moderated.status, 200);
    assert.equal(moderated.json.dlq_status.queue_depth, 0);
    assert.deepEqual(moderated.json.kicked_users, ['user-spammer']);

    const failed = await request(base, 'POST', '/audit/v1/moderation/test', {
      chat_room_id: 'chat-coverage',
      incoming_messages: [{ message_id: 'm4', sender: 'user-guest-1', text: 'Still clean' }],
      simulate_failed_notifications: 1,
    });
    assert.equal(failed.json.dlq_status.queue_depth, 1);
    const invalid = await request(base, 'POST', '/audit/v1/moderation/test', {});
    assert.equal(invalid.status, 400);
  });

  it('covers metrics, privacy erasure, and SSE score delivery', async () => {
    const merged = await request(base, 'POST', '/audit/v1/guest/cart-merge', {
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-1',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
      test_write_block: true,
    });
    assert.equal(merged.status, 200);
    assert.equal(merged.json.active_cart.total_items, 1);
    const replay = await request(base, 'POST', '/audit/v1/guest/cart-merge', {
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-1',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
      test_write_block: true,
    });
    assert.equal(replay.status, 200);
    assert.equal(replay.json.active_cart.total_items, 1);
    const conflict = await request(base, 'POST', '/audit/v1/guest/cart-merge', {
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-2',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
    });
    assert.equal(conflict.status, 409);
    const stock = await request(base, 'POST', '/audit/v1/guest/cart-merge', {
      guest_token: 'guest_stock_tok_1',
      registered_user_id: 'player-alpha-2',
      guest_cart: [{ variant_id: 'var-jersey-001-M', quantity: 9 }],
    });
    assert.equal(stock.status, 409);
    assert.equal(stock.json.error.code, 'OUT_OF_STOCK');

    const metrics = await request(base, 'GET', '/metrics');
    assert.match(metrics.text, /nascon_qr_scans_total/);

    const stream = await fetch(`${base}/api/v1/matches/match-m1/stream`);
    assert.equal(stream.status, 200);
    assert.match(stream.headers.get('content-type'), /text\/event-stream/);
    const reader = stream.body.getReader();
    const decoder = new TextDecoder();
    let buf = '';
    async function nextEvent(timeoutMs) {
      const started = Date.now();
      while (!buf.includes('\n\n')) {
        if (Date.now() - started > timeoutMs) throw new Error('SSE event timed out');
        const chunk = await reader.read();
        if (chunk.done) break;
        buf += decoder.decode(chunk.value, { stream: true });
      }
      const split = buf.indexOf('\n\n');
      const raw = buf.slice(0, split).replace(/^data: /, '');
      buf = buf.slice(split + 2);
      return JSON.parse(raw);
    }

    const initial = await nextEvent(1000);
    assert.equal(initial.home.score, 1);
    const postedAt = Date.now();
    const event = await request(base, 'POST', '/audit/v1/events', {
      event_id: 'coverage-goal',
      match_id: 'match-m1',
      type: 'score',
      payload: { team_id: 'club-alpha-1', event_type: 'goal' },
    });
    assert.equal(event.status, 201);
    const update = await nextEvent(500);
    assert.equal(update.home.score, 2);
    assert.ok(Date.now() - postedAt < 500);
    await reader.cancel();

    const erased = await request(base, 'DELETE', '/audit/v1/privacy/user/player-alpha-1');
    assert.equal(erased.status, 200);
    assert.equal(erased.json.pii_retained, false);
    const unknown = await request(base, 'DELETE', '/audit/v1/privacy/user/nobody');
    assert.equal(unknown.status, 404);
  });
});
