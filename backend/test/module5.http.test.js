const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");
const { lotsKey } = require("../src/canonical");

const BASE = process.env.AUDIT_BASE_URL || "http://127.0.0.1:8080";
let seq = 0;

async function request(method, path, body) {
  const options = { method, headers: {} };
  if (body !== undefined) {
    options.headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  return { status: res.status, json: await res.json() };
}

function nextId(prefix) {
  seq += 1;
  return `${prefix}-${seq}`;
}

async function createLeague(overrides = {}) {
  const leagueId = overrides.league_id || nextId("lg");
  const body = {
    league_id: leagueId,
    sport_id: overrides.sport_id || "football",
    teams: overrides.teams || ["t1", "t2", "t3", "t4"],
    fixtures: overrides.fixtures || [
      { match_id: `${leagueId}-m1`, home: "t1", away: "t2" },
      { match_id: `${leagueId}-m2`, home: "t3", away: "t4" },
    ],
    qualification: overrides.qualification || { spots: 2 },
    points: overrides.points,
    tie_break_order: overrides.tie_break_order,
    lots_seed: overrides.lots_seed,
  };
  if (!overrides.points) delete body.points;
  if (!overrides.tie_break_order) delete body.tie_break_order;
  if (overrides.lots_seed == null) delete body.lots_seed;
  const res = await request("POST", "/audit/v1/leagues", body);
  assert.equal(res.status, 201, JSON.stringify(res.json));
  return { leagueId, fixtures: body.fixtures, teams: body.teams };
}

async function play(matchId, homeGoals, awayGoals, extras = {}) {
  const prefix = nextId("e");
  assert.equal((await request("POST", "/audit/v1/events", { event_id: `${prefix}-s`, match_id: matchId, type: "match_start", payload: {} })).status, 201);
  const eventType = extras.event_type || "goal";
  for (let i = 0; i < homeGoals; i += 1) {
    assert.equal((await request("POST", "/audit/v1/events", { event_id: `${prefix}-h${i}`, match_id: matchId, type: "score", payload: { team_id: extras.home || "t1", event_type: eventType } })).status, 201);
  }
  for (let i = 0; i < awayGoals; i += 1) {
    assert.equal((await request("POST", "/audit/v1/events", { event_id: `${prefix}-a${i}`, match_id: matchId, type: "score", payload: { team_id: extras.away || "t2", event_type: eventType } })).status, 201);
  }
  if (extras.homeFairPlay) {
    await request("POST", "/audit/v1/events", { event_id: `${prefix}-dfh`, match_id: matchId, type: "discipline", payload: { team_id: extras.home || "t1", points: extras.homeFairPlay } });
  }
  if (extras.awayFairPlay) {
    await request("POST", "/audit/v1/events", { event_id: `${prefix}-dfa`, match_id: matchId, type: "discipline", payload: { team_id: extras.away || "t2", points: extras.awayFairPlay } });
  }
  if (extras.tiebreak) {
    await request("POST", "/audit/v1/events", { event_id: `${prefix}-tb`, match_id: matchId, type: "tiebreak_winner", payload: { team_id: extras.tiebreak } });
  }
  const ended = await request("POST", "/audit/v1/events", { event_id: `${prefix}-end`, match_id: matchId, type: "match_end", payload: {} });
  assert.equal(ended.status, 201, JSON.stringify(ended.json));
}

describe("Module 5 standings and qualification", { skip: process.env.SKIP_HTTP === "1" }, () => {
  before(async () => {
    const health = await request("GET", "/health");
    if (health.status !== 200) throw new Error("API not ready");
    await request("POST", "/audit/v1/reset", {});
  });

  it("returns empty standings, zero h2h pairs and 404 for unknown leagues", async () => {
    const { leagueId, teams } = await createLeague();
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    assert.equal(res.status, 200);
    assert.equal(res.json.league_id, leagueId);
    assert.equal(res.json.sport_id, "football");
    assert.equal(res.json.qualification_spots, 2);
    assert.equal(res.json.table.length, 4);
    assert.ok(res.json.table.every((row) => row.played === 0 && row.points === 0 && row.diff === 0 && row.status === "still_possible"));
    for (const a of teams) {
      for (const b of teams) {
        if (a === b) continue;
        assert.deepEqual(res.json.h2h[a][b], { played: 0, points: 0, scored: 0, conceded: 0 });
      }
    }
    const missing = await request("GET", "/audit/v1/standings/no-such-league");
    assert.equal(missing.status, 404);
    assert.equal(missing.json.error.code, "LEAGUE_NOT_FOUND");
  });

  it("counts completed results and ignores in-progress matches", async () => {
    const { leagueId, fixtures } = await createLeague();
    await play(fixtures[0].match_id, 2, 1);
    await request("POST", "/audit/v1/events", { event_id: nextId("live"), match_id: fixtures[1].match_id, type: "match_start", payload: {} });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const t1 = res.json.table.find((row) => row.team_id === "t1");
    const t3 = res.json.table.find((row) => row.team_id === "t3");
    assert.equal(t1.played, 1);
    assert.equal(t1.won, 1);
    assert.equal(t1.points, 3);
    assert.equal(t1.scored, 2);
    assert.equal(t1.conceded, 1);
    assert.equal(t1.diff, 1);
    assert.equal(t3.played, 0);
    assert.deepEqual(res.json.h2h.t1.t2, { played: 1, points: 3, scored: 2, conceded: 1 });
  });

  it("uses custom points, draws, event diffs and fair-play", async () => {
    const { leagueId, fixtures } = await createLeague({
      points: { win: 5, draw: 2, loss: 1 },
      fixtures: [
        { match_id: nextId("m"), home: "t1", away: "t2" },
        { match_id: nextId("m"), home: "t3", away: "t4" },
      ],
    });
    await play(fixtures[0].match_id, 1, 1, { homeFairPlay: -2 });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const t1 = res.json.table.find((row) => row.team_id === "t1");
    const t2 = res.json.table.find((row) => row.team_id === "t2");
    assert.equal(t1.drawn, 1);
    assert.equal(t1.points, 2);
    assert.equal(t2.points, 2);
    assert.equal(t1.fair_play, -2);
    assert.equal(t1.diff, 0);
  });

  it("computes round-model map differential", async () => {
    const { leagueId, fixtures } = await createLeague({
      sport_id: "esports",
      teams: ["t1", "t2"],
      fixtures: [{ match_id: nextId("rd"), home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    await play(fixtures[0].match_id, 2, 1, { event_type: "round_win" });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const t1 = res.json.table.find((row) => row.team_id === "t1");
    assert.equal(t1.scored, 2);
    assert.equal(t1.conceded, 1);
    assert.equal(t1.diff, 1);
  });

  it("computes innings NRR and all-out full overs", async () => {
    const { leagueId, fixtures } = await createLeague({
      sport_id: "cricket",
      teams: ["t1", "t2"],
      fixtures: [{ match_id: nextId("inn"), home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    const matchId = fixtures[0].match_id;
    const prefix = nextId("cr");
    await request("POST", "/audit/v1/events", { event_id: `${prefix}-s`, match_id: matchId, type: "match_start", payload: {} });
    for (let i = 0; i < 4; i += 1) {
      await request("POST", "/audit/v1/events", { event_id: `${prefix}-h${i}`, match_id: matchId, type: "score", payload: { team_id: "t1", event_type: "four" } });
    }
    for (let i = 0; i < 10; i += 1) {
      await request("POST", "/audit/v1/events", { event_id: `${prefix}-w${i}`, match_id: matchId, type: "score", payload: { team_id: "t2", event_type: "wicket" } });
    }
    await request("POST", "/audit/v1/events", { event_id: `${prefix}-end`, match_id: matchId, type: "match_end", payload: {} });
    const score = await request("GET", `/audit/v1/score/${matchId}`);
    assert.equal(score.json.home.score, 16);
    assert.equal(score.json.away.wickets, 10);
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const t1 = res.json.table.find((row) => row.team_id === "t1");
    const t2 = res.json.table.find((row) => row.team_id === "t2");
    assert.equal(t1.diff, 24);
    assert.equal(t2.diff, -24);
  });

  it("breaks two-team and three-way ties with mini-league restart and resolved_by", async () => {
    const m12 = nextId("m");
    const m23 = nextId("m");
    const m31 = nextId("m");
    const { leagueId } = await createLeague({
      teams: ["t1", "t2", "t3"],
      fixtures: [
        { match_id: m12, home: "t1", away: "t2" },
        { match_id: m23, home: "t2", away: "t3" },
        { match_id: m31, home: "t3", away: "t1" },
      ],
      qualification: { spots: 2 },
    });
    await play(m12, 3, 0, { home: "t1", away: "t2" });
    await play(m23, 2, 0, { home: "t2", away: "t3" });
    await play(m31, 1, 0, { home: "t3", away: "t1" });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    assert.deepEqual(res.json.table.map((row) => row.team_id), ["t1", "t2", "t3"]);
    assert.ok(res.json.table.every((row) => row.points === 3));
    assert.equal(res.json.table[0].diff, 2);
    assert.equal(res.json.table[0].resolved_by, "h2h_diff");
    assert.equal(res.json.table[1].resolved_by, "h2h_points");
    assert.equal(res.json.table[2].resolved_by, null);
  });

  it("uses overall_diff, fair_play and deterministic draw_lots", async () => {
    const lotsLeague = nextId("lg");
    const { leagueId } = await createLeague({
      league_id: lotsLeague,
      teams: ["t1", "t2", "t3"],
      fixtures: [
        { match_id: `${lotsLeague}-a`, home: "t1", away: "t2" },
        { match_id: `${lotsLeague}-b`, home: "t1", away: "t3" },
        { match_id: `${lotsLeague}-c`, home: "t2", away: "t3" },
      ],
      qualification: { spots: 1 },
      lots_seed: 42,
      tie_break_order: ["draw_lots"],
    });
    await play(`${lotsLeague}-a`, 1, 1, { home: "t1", away: "t2" });
    await play(`${lotsLeague}-b`, 1, 1, { home: "t1", away: "t3" });
    await play(`${lotsLeague}-c`, 1, 1, { home: "t2", away: "t3" });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const expected = ["t1", "t2", "t3"].sort((a, b) => lotsKey(42, lotsLeague, a).localeCompare(lotsKey(42, lotsLeague, b)));
    assert.deepEqual(res.json.table.map((row) => row.team_id), expected);
    assert.equal(res.json.table[0].resolved_by, "draw_lots");

    const fpA = nextId("m");
    const fpB = nextId("m");
    const { leagueId: fpLeague, fixtures } = await createLeague({
      teams: ["t1", "t2"],
      fixtures: [
        { match_id: fpA, home: "t1", away: "t2" },
        { match_id: fpB, home: "t1", away: "t2" },
      ],
      qualification: { spots: 1 },
      tie_break_order: ["fair_play", "draw_lots"],
    });
    await play(fpA, 1, 1, { homeFairPlay: -1 });
    const fair = await request("GET", `/audit/v1/standings/${fpLeague}`);
    assert.equal(fair.json.table[0].team_id, "t2");
    assert.equal(fair.json.table[0].resolved_by, "fair_play");
  });

  it("computes clinched, eliminated and still_possible from points only", async () => {
    const { leagueId, fixtures } = await createLeague({
      teams: ["t1", "t2", "t3", "t4"],
      fixtures: [
        { match_id: nextId("m"), home: "t1", away: "t2" },
        { match_id: nextId("m"), home: "t1", away: "t3" },
        { match_id: nextId("m"), home: "t1", away: "t4" },
        { match_id: nextId("m"), home: "t2", away: "t3" },
      ],
      qualification: { spots: 1 },
    });
    await play(fixtures[0].match_id, 1, 0, { home: "t1", away: "t2" });
    await play(fixtures[1].match_id, 1, 0, { home: "t1", away: "t3" });
    await play(fixtures[2].match_id, 1, 0, { home: "t1", away: "t4" });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    const byId = Object.fromEntries(res.json.table.map((row) => [row.team_id, row]));
    assert.equal(byId.t1.status, "clinched");
    assert.equal(byId.t2.status, "eliminated");
    assert.equal(byId.t3.status, "eliminated");
  });

  it("recomputes rankings and qualification after compensation", async () => {
    const { leagueId, fixtures } = await createLeague({
      teams: ["t1", "t2"],
      fixtures: [
        { match_id: nextId("m"), home: "t1", away: "t2" },
        { match_id: nextId("m"), home: "t1", away: "t2" },
      ],
      qualification: { spots: 1 },
    });
    await play(fixtures[0].match_id, 2, 1);
    const before = await request("GET", `/audit/v1/standings/${leagueId}`);
    assert.equal(before.json.table[0].team_id, "t1");
    assert.equal(before.json.table[0].status, "still_possible");
    const score = await request("GET", `/audit/v1/score/${fixtures[0].match_id}`);
    const homeGoals = score.json.events.filter((event) => event.type === "score" && event.payload.team_id === "t1");
    for (const goal of homeGoals) {
      const comp = await request("POST", "/audit/v1/events", {
        event_id: nextId("comp"),
        match_id: fixtures[0].match_id,
        type: "compensation",
        payload: { compensates: goal.event_id, reason: "offside" },
      });
      assert.equal(comp.status, 201);
    }
    const after = await request("GET", `/audit/v1/standings/${leagueId}`);
    assert.equal(after.json.table[0].team_id, "t2");
    assert.equal(after.json.table[0].won, 1);
    assert.equal(after.json.table[1].team_id, "t1");
  });

  it("supports a mystery sport from configuration only", async () => {
    const sport = await request("POST", "/audit/v1/sports", {
      sport_id: nextId("sp"),
      name: "Kabaddi",
      scoring_model: "event",
      periods: { count: 2, duration_minutes: 20 },
      scoring_events: { raid_point: { points: 1 } },
      draw_allowed: false,
      overtime: { policy: "none" },
      roster: { min_squad_size: 7, max_squad_size: 12, required_positions: {} },
    });
    const { leagueId, fixtures } = await createLeague({
      sport_id: sport.json.sport_id,
      teams: ["t1", "t2"],
      fixtures: [{ match_id: nextId("m"), home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    await play(fixtures[0].match_id, 2, 1, { event_type: "raid_point" });
    const res = await request("GET", `/audit/v1/standings/${leagueId}`);
    assert.equal(res.json.sport_id, sport.json.sport_id);
    assert.equal(res.json.table[0].team_id, "t1");
    assert.equal(res.json.table[0].scored, 2);
    assert.equal(res.json.table[0].diff, 1);
  });
});
