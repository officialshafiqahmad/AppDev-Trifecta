const test = require('node:test');
const assert = require('node:assert/strict');
const { validateSport, TIE_BREAKS } = require('../backend/src/sports');
const { validateReset, BASELINE_SPORTS } = require('../backend/src/baseline');

const kabaddi = {
  sport_id: 'kabaddi',
  name: 'Kabaddi',
  scoring_model: 'event',
  periods: { count: 2, duration_minutes: 20 },
  scoring_events: {
    raid_point: { points: 1 },
    tackle_point: { points: 1 },
    all_out: { points: 2 },
  },
  draw_allowed: false,
  overtime: { policy: 'golden_score', duration_minutes: 5 },
  tie_break_order: ['h2h_points', 'h2h_diff', 'overall_diff', 'scored', 'fair_play', 'draw_lots'],
  roster: { min_squad_size: 7, max_squad_size: 12, required_positions: { raider: 2, defender: 3 } },
  note: 'ignored',
};

test('baseline sports are stored through the same validator', () => {
  assert.deepEqual(
    BASELINE_SPORTS.map((sport) => sport.sport_id),
    ['football', 'basketball', 'cricket', 'esports'],
  );
  assert.deepEqual(BASELINE_SPORTS[0].tie_break_order, TIE_BREAKS);
  assert.equal(BASELINE_SPORTS[2].scoring_model, 'innings');
  assert.equal(BASELINE_SPORTS[3].periods.best_of, 3);
});

test('kabaddi example normalizes and drops unknown fields', () => {
  const result = validateSport(kabaddi);
  assert.equal(result.ok, true);
  assert.equal(result.config.note, undefined);
  assert.equal(result.config.scoring_events.raid_point.points, 1);
  assert.deepEqual(result.config.tie_break_order, TIE_BREAKS);
});

test('omitted tie-break order defaults to the full list', () => {
  const body = { ...kabaddi };
  delete body.tie_break_order;
  const result = validateSport(body);
  assert.equal(result.ok, true);
  assert.deepEqual(result.config.tie_break_order, TIE_BREAKS);
});

test('draw_lots is appended when omitted from a custom order', () => {
  const result = validateSport({ ...kabaddi, tie_break_order: ['scored', 'fair_play'] });
  assert.equal(result.ok, true);
  assert.deepEqual(result.config.tie_break_order, ['scored', 'fair_play', 'draw_lots']);
});

test('invalid sport fields are reported together', () => {
  const result = validateSport({
    sport_id: 'X',
    name: '',
    scoring_model: 'chess',
    periods: {},
    scoring_events: {},
    draw_allowed: 'yes',
    overtime: { policy: 'sudden_death' },
    tie_break_order: ['h2h_points', 'h2h_points'],
    roster: { min_squad_size: 8, max_squad_size: 3, required_positions: {} },
  });
  assert.equal(result.ok, false);
  assert.deepEqual(result.fields, [
    'sport_id',
    'name',
    'scoring_model',
    'scoring_events',
    'draw_allowed',
    'overtime',
    'tie_break_order',
    'roster',
  ]);
});

test('round and innings fragments validate', () => {
  const innings = validateSport({
    ...kabaddi,
    sport_id: 'mystery-innings',
    scoring_model: 'innings',
    periods: { innings_per_team: 1, overs_per_innings: 10, balls_per_over: 6, wickets_per_innings: 10 },
    scoring_events: {
      super_six: { runs: 6, legal_ball: true, wicket: false },
      bye_run: { runs: 1, legal_ball: false, wicket: false },
      out: { runs: 0, legal_ball: true, wicket: true },
    },
  });
  const round = validateSport({
    ...kabaddi,
    sport_id: 'mystery-round',
    scoring_model: 'round',
    periods: { best_of: 5 },
    scoring_events: { map_win: { rounds: 1 } },
  });
  assert.equal(innings.ok, true);
  assert.equal(round.ok, true);
  assert.equal(validateSport({ ...kabaddi, scoring_model: 'round', periods: { best_of: 2 }, scoring_events: { map_win: { rounds: 1 } } }).ok, false);
});

test('reset defaults and rejects a bad seed or stock', () => {
  assert.deepEqual(validateReset(undefined), {
    ok: true,
    seed: 42,
    stock: { 'var-jersey-001-M': 1, 'var-jersey-001-L': 5 },
  });
  assert.deepEqual(validateReset({ seed: 7, stock: { 'var-jersey-001-M': 0 }, extra: true }), {
    ok: true,
    seed: 7,
    stock: { 'var-jersey-001-M': 0, 'var-jersey-001-L': 5 },
  });
  assert.deepEqual(validateReset({ seed: 1.5 }).fields, ['seed']);
  assert.deepEqual(validateReset({ stock: { 'var-jersey-001-M': -1 } }).fields, ['stock']);
  assert.deepEqual(validateReset([]).fields, ['body']);
});
