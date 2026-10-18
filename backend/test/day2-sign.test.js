const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { BASELINE_SPORTS } = require('../src/baseline');
const { projectMatch } = require('../src/scoring');
const { buildMatchM1Events, PHASE2_MATCH, PHASE2_QR, PHASE2_GUEST } = require('../src/day2/baseline');
const { signDay2, day2Salt } = require('../src/day2/sign');

const REFERENCE_SALT = 'T01D27ad7ffff12e';

describe('DAY2_SALT signatures', () => {
  it('matches Appendix A vector 1', () => {
    const payload = {
      action: 'rotate',
      player_id: 'player-alpha-1',
      status: 'active',
      stream_key: 'sk_live_9f83a1b2c3d4e5f6',
    };
    assert.equal(
      signDay2(REFERENCE_SALT, 'sk_live_9f83a1b2c3d4e5f6', payload),
      '9bd054eb746844b4701c6f158209c315ef2b16f392efd733bdf0715940610289',
    );
  });

  it('matches Appendix A vector 2', () => {
    assert.equal(
      signDay2(REFERENCE_SALT, 'sk_live_101', {
        action: 'rotate',
        player_id: 'player-alpha-1',
      }),
      '830b24eb2c795c02c54c17516b0e96870f5b65d98d28c2f0a15619ec3e076188',
    );
  });

  it('reads DAY2_SALT from the environment and rejects a missing salt', () => {
    const previous = process.env.DAY2_SALT;
    process.env.DAY2_SALT = REFERENCE_SALT;
    try {
      assert.equal(day2Salt(), REFERENCE_SALT);
    } finally {
      if (previous === undefined) delete process.env.DAY2_SALT;
      else process.env.DAY2_SALT = previous;
    }
    const saved = process.env.DAY2_SALT;
    delete process.env.DAY2_SALT;
    assert.throws(() => day2Salt(), /DAY2_SALT must be set/);
    if (saved !== undefined) process.env.DAY2_SALT = saved;
  });
});

describe('Phase II reset seed plan', () => {
  it('projects match-m1 to in_progress with score 1-0', () => {
    const football = BASELINE_SPORTS.find((sport) => sport.sport_id === 'football');
    const events = buildMatchM1Events('demo-salt');
    const projection = projectMatch(
      {
        match_id: PHASE2_MATCH.match_id,
        home_team_id: PHASE2_MATCH.home_team_id,
        away_team_id: PHASE2_MATCH.away_team_id,
      },
      football,
      events,
    );
    assert.equal(projection.status, 'in_progress');
    assert.equal(projection.home.score, 1);
    assert.equal(projection.away.score, 0);
    assert.equal(events[0].signature.length, 64);
  });

  it('keeps the required QR mappings and guest token', () => {
    assert.deepEqual(PHASE2_QR.map((row) => row.short_url), [
      'http://localhost:8080/q/m1-live',
      'http://localhost:8080/q/p-alpha-1',
      'http://localhost:8080/q/c-alpha-1',
    ]);
    assert.equal(PHASE2_QR[0].scan_count, 0);
    assert.equal(PHASE2_GUEST.guest_token, 'guest_anon_tok_7721');
    assert.equal(PHASE2_GUEST.merged, false);
  });
});
