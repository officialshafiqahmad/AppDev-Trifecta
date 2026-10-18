const test = require('node:test');
const assert = require('node:assert/strict');

const base = process.env.API_BASE || 'http://127.0.0.1:8080';

async function request(method, path, body, headers = {}) {
  const hasBody = body !== undefined;
  const response = await fetch(`${base}${path}`, {
    method,
    headers: hasBody ? { 'content-type': 'application/json', ...headers } : headers,
    body: hasBody ? (typeof body === 'string' ? body : JSON.stringify(body)) : undefined,
  });
  const text = await response.text();
  let json = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = text;
    }
  }
  return { status: response.status, json, text };
}

const kabaddi = {
  sport_id: 'kabaddi',
  name: 'Kabaddi',
  scoring_model: 'event',
  periods: { count: 2, duration_minutes: 20, ignored: true },
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

test('GET /health reports seeded readiness', async () => {
  const health = await request('GET', '/health');
  assert.equal(health.status, 200);
  assert.deepEqual(health.json, { status: 'ok' });
});

test('POST /audit/v1/reset is repeatable', async () => {
  const first = await request('POST', '/audit/v1/reset', {});
  const second = await request('POST', '/audit/v1/reset');
  assert.equal(first.status, 200);
  assert.deepEqual(first.json, {
    status: 'reset_complete',
    seed: 42,
    sports: ['football', 'basketball', 'cricket', 'esports'],
    tenants: ['tenant-alpha', 'tenant-beta'],
    stock: { 'var-jersey-001-M': 1, 'var-jersey-001-L': 5 },
  });
  assert.deepEqual(second.json, first.json);
});

test('POST /audit/v1/reset accepts seed and stock overrides', async () => {
  const response = await request('POST', '/audit/v1/reset', {
    seed: 7,
    stock: { 'var-jersey-001-L': 0 },
    ignored: true,
  });
  assert.equal(response.status, 200);
  assert.equal(response.json.seed, 7);
  assert.deepEqual(response.json.stock, { 'var-jersey-001-M': 1, 'var-jersey-001-L': 0 });
  await request('POST', '/audit/v1/reset', {});
});

test('POST /audit/v1/reset rejects a non-integer seed before any write', async () => {
  const response = await request('POST', '/audit/v1/reset', { seed: '42' });
  assert.equal(response.status, 400);
  assert.equal(response.json.error.code, 'VALIDATION_ERROR');
  assert.deepEqual(response.json.error.details.fields, ['seed']);
});

test('POST /audit/v1/sports creates a mystery sport and rejects a duplicate', async () => {
  await request('POST', '/audit/v1/reset', {});
  const created = await request('POST', '/audit/v1/sports', kabaddi);
  assert.equal(created.status, 201);
  assert.equal(created.json.sport_id, 'kabaddi');
  assert.equal(created.json.status, 'created');
  assert.equal(created.json.config.note, undefined);
  assert.equal(created.json.config.periods.ignored, undefined);
  assert.equal(created.json.config.scoring_events.all_out.points, 2);
  assert.equal(created.json.config.roster.required_positions.raider, 2);

  const duplicate = await request('POST', '/audit/v1/sports', kabaddi);
  assert.equal(duplicate.status, 409);
  assert.equal(duplicate.json.error.code, 'SPORT_EXISTS');
  assert.deepEqual(duplicate.json.error.details, { sport_id: 'kabaddi' });
});

test('reset removes a custom sport', async () => {
  await request('POST', '/audit/v1/reset', {});
  assert.equal((await request('POST', '/audit/v1/sports', kabaddi)).status, 201);
  assert.equal((await request('POST', '/audit/v1/reset', {})).status, 200);
  assert.equal((await request('POST', '/audit/v1/sports', kabaddi)).status, 201);
});

test('invalid sport schema returns VALIDATION_ERROR and does not create', async () => {
  await request('POST', '/audit/v1/reset', {});
  const response = await request('POST', '/audit/v1/sports', {
    sport_id: "x'; DROP TABLE sports;--",
    name: 'Bad',
    scoring_model: 'event',
    periods: { count: 1, duration_minutes: 1 },
    scoring_events: { goal: { points: 1 } },
    draw_allowed: true,
    overtime: { policy: 'none' },
    roster: { min_squad_size: 1, max_squad_size: 2, required_positions: {} },
  });
  assert.equal(response.status, 400);
  assert.equal(response.json.error.code, 'VALIDATION_ERROR');
  assert.ok(response.json.error.details.fields.includes('sport_id'));

  const created = await request('POST', '/audit/v1/sports', {
    ...kabaddi,
    sport_id: 'kabaddi',
  });
  assert.equal(created.status, 201);
});

test('malformed JSON is 400 and an oversized body is 413', async () => {
  const malformed = await request('POST', '/audit/v1/sports', '{');
  assert.equal(malformed.status, 400);
  assert.equal(malformed.json.error.code, 'VALIDATION_ERROR');
  assert.deepEqual(malformed.json.error.details.fields, []);

  const oversized = await request('POST', '/audit/v1/sports', { pad: 'x'.repeat(1024 * 1024) });
  assert.equal(oversized.status, 413);
  assert.equal(oversized.json.error.code, 'PAYLOAD_TOO_LARGE');
});
