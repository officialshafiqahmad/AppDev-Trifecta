const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { guestWriteBlock, guestWriteDecision } = require('../src/day2/guest');
const { validateCartMerge, combineCart } = require('../src/day2/cart-merge');
const { moderateMessages, normalizeToken } = require('../src/day2/moderation');

describe('guest write boundary', () => {
  it('blocks guest tokens on checkout, events, and chat', () => {
    for (const path of ['/audit/v1/checkout', '/audit/v1/events', '/api/v1/chat']) {
      const decision = guestWriteBlock({
        method: 'POST',
        path,
        headers: { authorization: 'Bearer guest_anon_tok_7721' },
      });
      assert.equal(decision.status, 403);
      assert.equal(decision.code, 'GUEST_WRITE_FORBIDDEN');
      assert.equal(decision.token, 'guest_anon_tok_7721');
    }
  });

  it('allows Day 1 writes that do not carry a guest token', () => {
    assert.equal(guestWriteBlock({
      method: 'POST',
      path: '/audit/v1/events',
      headers: {},
    }), null);
    assert.equal(guestWriteDecision('user-token').blocked, false);
  });
});

describe('guest cart merge validation', () => {
  it('defaults the write probe and rejects a short token', () => {
    const parsed = validateCartMerge({
      guest_token: 'guest_anon_tok_7721',
      registered_user_id: 'player-alpha-1',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
    });
    assert.equal(parsed.ok, true);
    assert.equal(parsed.test_write_block, true);
    assert.ok(validateCartMerge({
      guest_token: 'anon',
      registered_user_id: 'player-alpha-1',
      guest_cart: [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
    }).fields.includes('guest_token'));
  });

  it('sums quantities for the same variant', () => {
    const combined = combineCart(
      [{ variant_id: 'var-jersey-001-L', quantity: 1 }],
      [{ variant_id: 'var-jersey-001-L', quantity: 2 }],
    );
    assert.equal(combined.quantities.get('var-jersey-001-L'), 3);
  });
});

describe('chat moderation', () => {
  it('normalizes leetspeak and masks only the offending token', () => {
    assert.equal(normalizeToken('b@d_w0rd'), 'badword');
    assert.equal(normalizeToken('p.0.r.n'), 'porn');
    assert.equal(normalizeToken('a$$h0le'), 'asshole');
    const result = moderateMessages([
      { message_id: 'msg-1', sender: 'user-guest-1', text: 'Clean sports commentary' },
      { message_id: 'msg-2', sender: 'user-spammer', text: 'Watch this illegal stream b@d_w0rd now!' },
      { message_id: 'msg-3', sender: 'user-flooder', text: 'GOAL! AAAA!!!' },
    ]);
    assert.equal(result.filtered.length, 2);
    assert.equal(result.filtered[0].flagged, false);
    assert.equal(result.filtered[0].reason, null);
    assert.equal(result.filtered[1].text, 'Watch this illegal stream *** now!');
    assert.equal(result.filtered[1].reason, 'profanity_leetspeak');
    assert.deepEqual(result.kicked, ['user-spammer']);
    assert.deepEqual(result.muted, ['user-flooder']);
  });

  it('deduplicates a repeated kick', () => {
    const result = moderateMessages([
      { message_id: 'a', sender: 'user-spammer', text: 'b@d_w0rd' },
      { message_id: 'b', sender: 'user-spammer', text: 'p0rn' },
    ]);
    assert.deepEqual(result.kicked, ['user-spammer']);
  });
});
