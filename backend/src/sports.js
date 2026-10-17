const TIE_BREAKS = ['h2h_points', 'h2h_diff', 'overall_diff', 'scored', 'fair_play', 'draw_lots'];
const TIE_SET = new Set(TIE_BREAKS);
const POLICIES = new Set(['none', 'extra_time', 'shootout', 'golden_score', 'super_over']);
const MODELS = new Set(['event', 'innings', 'round']);
const FIELD_ORDER = [
  'body',
  'sport_id',
  'name',
  'scoring_model',
  'periods',
  'scoring_events',
  'draw_allowed',
  'overtime',
  'tie_break_order',
  'roster',
];
const EVENT_KEY = /^[a-z0-9_]{1,40}$/;
const SPORT_ID = /^[a-z0-9_-]{2,40}$/;

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isInt(value) {
  return typeof value === 'number' && Number.isInteger(value);
}

function validatePeriods(model, periods) {
  if (!isPlainObject(periods)) return null;
  if (model === 'event') {
    if (!isInt(periods.count) || periods.count < 1) return null;
    if (!isInt(periods.duration_minutes) || periods.duration_minutes < 1) return null;
    return { count: periods.count, duration_minutes: periods.duration_minutes };
  }
  if (model === 'innings') {
    const keys = ['innings_per_team', 'overs_per_innings', 'balls_per_over', 'wickets_per_innings'];
    if (keys.some((key) => !isInt(periods[key]) || periods[key] < 1)) return null;
    return {
      innings_per_team: periods.innings_per_team,
      overs_per_innings: periods.overs_per_innings,
      balls_per_over: periods.balls_per_over,
      wickets_per_innings: periods.wickets_per_innings,
    };
  }
  if (model === 'round') {
    if (!isInt(periods.best_of) || periods.best_of < 1 || periods.best_of % 2 === 0) return null;
    return { best_of: periods.best_of };
  }
  return null;
}

function validateEvents(model, events) {
  if (!isPlainObject(events)) return null;
  const keys = Object.keys(events);
  if (keys.length < 1) return null;
  const stored = {};
  for (const key of keys) {
    if (!EVENT_KEY.test(key) || !isPlainObject(events[key])) return null;
    const value = events[key];
    if (model === 'event') {
      if (!isInt(value.points) || value.points < 1) return null;
      stored[key] = { points: value.points };
    } else if (model === 'innings') {
      if (!isInt(value.runs) || value.runs < 0) return null;
      if (typeof value.legal_ball !== 'boolean' || typeof value.wicket !== 'boolean') return null;
      stored[key] = { runs: value.runs, legal_ball: value.legal_ball, wicket: value.wicket };
    } else if (model === 'round') {
      if (!isInt(value.rounds) || value.rounds < 1) return null;
      stored[key] = { rounds: value.rounds };
    } else {
      return null;
    }
  }
  return stored;
}

function validateOvertime(overtime) {
  if (!isPlainObject(overtime) || !POLICIES.has(overtime.policy)) return null;
  const stored = { policy: overtime.policy };
  if (Object.prototype.hasOwnProperty.call(overtime, 'duration_minutes')) {
    if (!isInt(overtime.duration_minutes) || overtime.duration_minutes < 0) return null;
    stored.duration_minutes = overtime.duration_minutes;
  }
  return stored;
}

function validateRoster(roster) {
  if (!isPlainObject(roster)) return null;
  const { min_squad_size: min, max_squad_size: max, required_positions: positions } = roster;
  if (!isInt(min) || min < 1 || !isInt(max) || max < 1 || min > max) return null;
  if (!isPlainObject(positions)) return null;
  const stored = {};
  for (const [key, count] of Object.entries(positions)) {
    if (typeof key !== 'string' || key.length < 1 || key.length > 40 || key.includes('|')) return null;
    if (!isInt(count) || count < 0) return null;
    stored[key] = count;
  }
  return { min_squad_size: min, max_squad_size: max, required_positions: stored };
}

function validateTieBreak(body) {
  if (!Object.prototype.hasOwnProperty.call(body, 'tie_break_order')) {
    return { ok: true, order: TIE_BREAKS.slice() };
  }
  const order = body.tie_break_order;
  if (!Array.isArray(order)) return { ok: false };
  const seen = new Set();
  for (const item of order) {
    if (typeof item !== 'string' || !TIE_SET.has(item) || seen.has(item)) return { ok: false };
    seen.add(item);
  }
  const withoutLots = order.filter((item) => item !== "draw_lots");
  return { ok: true, order: withoutLots.concat("draw_lots") };
}

function validateSport(body) {
  const bad = new Set();
  if (!isPlainObject(body)) {
    return { ok: false, fields: ['body'] };
  }

  if (typeof body.sport_id !== 'string' || !SPORT_ID.test(body.sport_id)) bad.add('sport_id');
  if (typeof body.name !== 'string' || body.name.length < 1 || body.name.length > 80) bad.add('name');

  const modelOk = typeof body.scoring_model === 'string' && MODELS.has(body.scoring_model);
  if (!modelOk) bad.add('scoring_model');
  const model = modelOk ? body.scoring_model : null;

  let storedPeriods = null;
  if (!isPlainObject(body.periods)) bad.add('periods');
  else if (model) {
    storedPeriods = validatePeriods(model, body.periods);
    if (!storedPeriods) bad.add('periods');
  }

  let storedEvents = null;
  if (!isPlainObject(body.scoring_events) || Object.keys(body.scoring_events).length < 1) {
    bad.add('scoring_events');
  } else if (!model) {
    const keysOk = Object.entries(body.scoring_events).every(([key, value]) => (
      EVENT_KEY.test(key) && isPlainObject(value)
    ));
    if (!keysOk) bad.add('scoring_events');
  } else {
    storedEvents = validateEvents(model, body.scoring_events);
    if (!storedEvents) bad.add('scoring_events');
  }

  if (typeof body.draw_allowed !== 'boolean') bad.add('draw_allowed');

  const storedOvertime = validateOvertime(body.overtime);
  if (storedOvertime === null) bad.add('overtime');

  const tie = validateTieBreak(body);
  if (!tie.ok) bad.add('tie_break_order');

  const storedRoster = validateRoster(body.roster);
  if (storedRoster === null) bad.add('roster');

  if (bad.size > 0) {
    return { ok: false, fields: FIELD_ORDER.filter((field) => bad.has(field)) };
  }

  return {
    ok: true,
    config: {
      sport_id: body.sport_id,
      name: body.name,
      scoring_model: model,
      periods: storedPeriods,
      scoring_events: storedEvents,
      draw_allowed: body.draw_allowed,
      overtime: storedOvertime,
      tie_break_order: tie.order,
      roster: storedRoster,
    },
  };
}

async function createSport(pool, config) {
  const existing = await pool.query("SELECT sport_id FROM sports WHERE sport_id = $1", [config.sport_id]);
  if (existing.rowCount > 0) {
    return { exists: true };
  }
  await pool.query(
    `INSERT INTO sports (sport_id, name, scoring_model, config, is_baseline)
     VALUES ($1, $2, $3, $4::jsonb, FALSE)`,
    [config.sport_id, config.name, config.scoring_model, JSON.stringify(config)]
  );
  return { exists: false };
}

module.exports = { validateSport, createSport, TIE_BREAKS };
