const { describe, it, before } = require('node:test');
const assert = require('node:assert/strict');
const { signDay2 } = require('../src/day2/sign');

const BASE = process.env.AUDIT_BASE_URL || 'http://127.0.0.1:8080';
const DAY2 = process.env.DAY2_SALT;
const GUEST = { Authorization: 'Bearer guest_anon_tok_7721' };

async function request(method, path, body, headers = {}) {
  const options = { method, headers: { ...headers } };
  if (body !== undefined) {
    options.headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_err) {
    json = text;
  }
  return { status: res.status, json, text, type: res.headers.get('content-type') };
}

describe('Phase II guest, moderation, and metrics HTTP', { skip: process.env.SKIP_HTTP === '1' }, () => {
  before(async () => {
    assert.ok(DAY2);
    const reset = await request('POST', '/audit/v1/reset', {});
    assert.equal(reset.status, 200);
  });

  it('rejects guest writes with 403 and leaves Day 1 checkout open', async () => {
    const event = await request('POST', '/audit/v1/events', {
      event_id: 'guest-should-not-land',
      match_id: 'match-m1',
      type: 'score',
      payload: { team_id: 'club-alpha-1', event_type: 'goal' },
    }, GUEST);
    assert.equal(event.status, 403);
    assert.equal(event.json.error.code, 'GUEST_WRITE_FORBIDDEN');
    assert.equal(event.json.error.details.guest_token, 'guest_anon_tok_7721');

    const checkout = await request('POST', '/audit/v1/checkout', { order_id: 'guest-order' }, GUEST);
    assert.equal(checkout.status, 403);
    assert.equal(checkout.json.error.code, 'GUEST_WRITE_FORBIDDEN');

    const chat = await request('POST', '/api/v1/chat', { text: 'hello' }, GUEST);
    assert.equal(chat.status, 403);
    assert.equal(chat.json.error.code, 'GUEST_WRITE_FORBIDDEN');

    const score = await request('GET', '/audit/v1/score/match-m1');
    assert.equal(score.json.home.score, 1);
    assert.equal(score.json.version, 3);
  });

  it('merges a guest cart once and replays without doubling', async () => {
    const payload = {
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-1',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
      test_write_block: true,
    };
    const merged = await request('POST', '/audit/v1/guest/cart-merge', payload);
    assert.equal(merged.status, 200);
    assert.equal(merged.json.write_block_verified, true);
    assert.equal(merged.json.write_rejection_code, 403);
    assert.equal(merged.json.cart_merged, true);
    assert.equal(merged.json.active_cart.total_items, 1);
    assert.equal(merged.json.active_cart.subtotal_minor, 450000);
    assert.deepEqual(merged.json.active_cart.items, [{
      variant_id: 'var-jersey-001-L',
      quantity: 1,
      unit_price_minor: 450000,
    }]);
    assert.equal(merged.json.signature, signDay2(DAY2, 'guest_anon_tok_7721', {
      cart_merged: true,
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-1',
      total_items: 1,
      write_rejection_code: 403,
    }));

    const replay = await request('POST', '/audit/v1/guest/cart-merge', payload);
    assert.equal(replay.status, 200);
    assert.equal(replay.json.active_cart.total_items, 1);
    assert.equal(replay.json.signature, merged.json.signature);

    const conflict = await request('POST', '/audit/v1/guest/cart-merge', {
      ...payload,
      guest_cart: [{ variant_id: 'var-jersey-001-M', quantity: 1 }],
    });
    assert.equal(conflict.status, 409);
    assert.equal(conflict.json.error.code, 'GUEST_TOKEN_ALREADY_MERGED');

    const stock = await request('GET', '/audit/v1/inventory/var-jersey-001-L');
    assert.equal(stock.json.stock, 5);
  });

  it('masks profanity, drops floods, and exposes metrics', async () => {
    const moderated = await request('POST', '/audit/v1/moderation/test', {
      chat_room_id: 'chat-cs-session-101',
      incoming_messages: [
        { message_id: 'msg-1', sender: 'user-guest-1', text: 'Clean sports commentary' },
        { message_id: 'msg-2', sender: 'user-spammer', text: 'Watch this illegal stream b@d_w0rd now!' },
        { message_id: 'msg-3', sender: 'user-flooder', text: 'GOAL! AAAA!!!' },
      ],
      check_dlq: true,
      simulate_failed_notifications: 0,
    });
    assert.equal(moderated.status, 200);
    assert.equal(moderated.json.filtered_messages.length, 2);
    assert.equal(moderated.json.filtered_messages[1].text, 'Watch this illegal stream *** now!');
    assert.deepEqual(moderated.json.kicked_users, ['user-spammer']);
    assert.deepEqual(moderated.json.muted_users, ['user-flooder']);
    assert.equal(moderated.json.dlq_status.queue_depth, 0);
    assert.equal(moderated.json.signature, signDay2(DAY2, 'chat-cs-session-101', {
      chat_room_id: 'chat-cs-session-101',
      flagged_count: 1,
      kicked_users: ['user-spammer'],
      queue_depth: 0,
    }));

    const failed = await request('POST', '/audit/v1/moderation/test', {
      chat_room_id: 'chat-cs-session-101',
      incoming_messages: [
        { message_id: 'msg-9', sender: 'user-guest-1', text: 'Still clean' },
      ],
      simulate_failed_notifications: 2,
    });
    assert.equal(failed.json.dlq_status.queue_depth, 2);
    assert.equal(failed.json.dlq_status.undelivered_events.length, 2);

    const metrics = await request('GET', '/metrics');
    assert.equal(metrics.status, 200);
    assert.equal(metrics.type, 'text/plain; version=0.0.4');
    assert.match(metrics.text, /^nascon_active_ws_connections \d+$/m);
    assert.match(metrics.text, /^nascon_active_streams_total \d+$/m);
    assert.match(metrics.text, /^nascon_stream_bitrate_kbps \d+$/m);
    assert.match(metrics.text, /^nascon_dlq_depth 2$/m);
    assert.match(metrics.text, /^nascon_qr_scans_total \d+$/m);
  });

  it('anonymizes a player and wipes linked viewer tokens', async () => {
    const erased = await request('DELETE', '/audit/v1/privacy/user/player-alpha-1');
    assert.equal(erased.status, 200);
    assert.deepEqual(erased.json, {
      user_id: 'player-alpha-1',
      status: 'anonymized',
      pii_retained: false,
      tokens_wiped: true,
    });

    const again = await request('DELETE', '/audit/v1/privacy/user/player-alpha-1');
    assert.equal(again.status, 200);
    assert.equal(again.json.status, 'anonymized');

    const missing = await request('DELETE', '/audit/v1/privacy/user/player-missing');
    assert.equal(missing.status, 404);
    assert.equal(missing.json.error.code, 'PLAYER_NOT_FOUND');
  });

  it('serves the guest live page with the required selectors', async () => {
    const page = await request('GET', '/web/matches/match-m1/live');
    assert.equal(page.status, 200);
    assert.match(page.type, /text\/html/);
    assert.match(page.text, /data-testid="guest-video-player"/);
    assert.match(page.text, /data-testid="live-score-banner"/);
    assert.match(page.text, /1 - 0/);
    assert.match(page.text, /data-testid="progressive-auth-modal"[^>]*hidden/);
  });
});