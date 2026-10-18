const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { collectIdentityIds, erasedEmail, erasureResponse, eraseUser } = require('../src/day2/privacy');
const { renderMetrics } = require('../src/day2/metrics');
const { renderGuestHtml } = require('../src/day2/web');

function scriptedPool(results) {
  const client = {
    async query(sql) {
      const next = results.shift();
      if (!next) throw new Error(`unexpected query: ${sql}`);
      if (next.match && !sql.includes(next.match)) {
        throw new Error(`expected ${next.match} in ${sql}`);
      }
      return next.result || { rowCount: 0, rows: [] };
    },
    release() {},
  };
  return { async connect() { return client; } };
}

describe('privacy erasure', () => {
  it('anonymizes the linked player and user without keeping the original email', () => {
    const ids = collectIdentityIds('player-alpha-1', [
      { user_id: 'user-player', player_id: 'player-alpha-1' },
    ]);
    assert.deepEqual(ids.sort(), ['player-alpha-1', 'user-player']);
    assert.equal(erasedEmail('user-player'), 'erased+user-player@privacy.invalid');
    assert.equal(erasedEmail('user-player').includes('player@nascon.test'), false);
    assert.deepEqual(erasureResponse('player-alpha-1'), {
      user_id: 'player-alpha-1',
      status: 'anonymized',
      pii_retained: false,
      tokens_wiped: true,
    });
  });

  it('rejects an empty id before touching the database', async () => {
    const missing = await eraseUser(null, '');
    assert.equal(missing.error.status, 400);
    assert.deepEqual(missing.error.details.fields, ['user_id']);
  });

  it('returns 404 when neither the user nor the player exists', async () => {
    const pool = scriptedPool([
      { match: 'BEGIN' },
      { match: 'FROM users', result: { rowCount: 0, rows: [] } },
      { match: 'FROM players', result: { rowCount: 0, rows: [] } },
      { match: 'ROLLBACK' },
    ]);
    const result = await eraseUser(pool, 'player-missing');
    assert.equal(result.error.status, 404);
    assert.equal(result.error.code, 'PLAYER_NOT_FOUND');
  });

  it('anonymizes the account and unlinks guest and viewer tokens', async () => {
    const pool = scriptedPool([
      { match: 'BEGIN' },
      { match: 'FROM users', result: { rowCount: 1, rows: [{ user_id: 'user-player', player_id: 'player-alpha-1' }] } },
      { match: 'FROM players', result: { rowCount: 1, rows: [{ player_id: 'player-alpha-1' }] } },
      { match: 'UPDATE users' },
      { match: 'UPDATE players' },
      { match: 'FROM guest_merges', result: { rowCount: 1, rows: [{ guest_token: 'guest_anon_tok_7721' }] } },
      { match: 'UPDATE guest_sessions' },
      { match: 'DELETE FROM guest_merges' },
      { match: 'DELETE FROM viewer_tokens' },
      { match: 'COMMIT' },
    ]);
    const result = await eraseUser(pool, 'player-alpha-1');
    assert.equal(result.status, 200);
    assert.equal(result.body.tokens_wiped, true);
    assert.equal(result.body.pii_retained, false);
  });
});

describe('metrics', () => {
  it('renders the five Prometheus series', async () => {
    const pool = {
      async query(sql) {
        if (sql.includes('stream_keys')) return { rows: [{ n: 2 }] };
        if (sql.includes('qr_links')) return { rows: [{ n: 4 }] };
        return { rows: [{ n: 1 }] };
      },
    };
    const text = await renderMetrics(pool, 3);
    assert.match(text, /^nascon_active_ws_connections 3$/m);
    assert.match(text, /^nascon_active_streams_total 2$/m);
    assert.match(text, /^nascon_stream_bitrate_kbps 0$/m);
    assert.match(text, /^nascon_dlq_depth 1$/m);
    assert.match(text, /^nascon_qr_scans_total 4$/m);
  });
});

describe('guest web player', () => {
  it('exposes the nine grader selectors and hides the auth modal', () => {
    const html = renderGuestHtml({
      title: 'Live match-m1',
      matchId: 'match-m1',
      scoreText: '1 - 0',
      playbackUrl: 'http://localhost:8888/live/match-m1/index.m3u8',
    });
    for (const id of [
      'guest-video-player',
      'live-score-banner',
      'pinned-merch-card',
      'add-to-guest-cart-btn',
      'guest-cart-count',
      'chat-message-list',
      'chat-input-field',
      'chat-send-btn',
      'progressive-auth-modal',
    ]) {
      assert.match(html, new RegExp(`data-testid="${id}"`));
    }
    assert.match(html, /data-testid="progressive-auth-modal"[^>]*hidden/);
    assert.match(html, /1 - 0/);
    assert.match(html, /var-jersey-001-L/);
    assert.equal(html.includes('<script>'), true);
  });
});
