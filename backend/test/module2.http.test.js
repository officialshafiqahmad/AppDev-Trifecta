const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");
const { sign } = require("../src/canonical");

const BASE = process.env.AUDIT_BASE_URL || "http://127.0.0.1:8080";
const SALT = process.env.DAY1_SALT || "module1-test-salt";

async function request(method, path, body) {
  const options = { method, headers: {} };
  if (body !== undefined) {
    options.headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  return { status: res.status, json: await res.json() };
}

describe("Module 2 leagues and scoring HTTP", { skip: process.env.SKIP_HTTP === "1" }, () => {
  before(async () => {
    const health = await request("GET", "/health");
    if (health.status !== 200) throw new Error("API not ready");
    const reset = await request("POST", "/audit/v1/reset", {});
    assert.equal(reset.status, 200);
  });

  it("creates a league and rejects invalid and duplicate leagues", async () => {
    const created = await request("POST", "/audit/v1/leagues", {
      league_id: "lg-1",
      sport_id: "football",
      teams: ["t1", "t2", "t3", "t4"],
      fixtures: [
        { match_id: "m1", home: "t1", away: "t2" },
        { match_id: "m2", home: "t3", away: "t4" },
      ],
      qualification: { spots: 2 },
    });
    assert.equal(created.status, 201);
    assert.deepEqual(created.json, {
      league_id: "lg-1",
      status: "created",
      team_count: 4,
      fixture_count: 2,
    });

    const missingSport = await request("POST", "/audit/v1/leagues", {
      league_id: "lg-missing-sport",
      sport_id: "does-not-exist",
      teams: ["t1", "t2"],
      fixtures: [{ match_id: "mx", home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    assert.equal(missingSport.status, 404);
    assert.equal(missingSport.json.error.code, "SPORT_NOT_FOUND");

    const dupLeague = await request("POST", "/audit/v1/leagues", {
      league_id: "lg-1",
      sport_id: "football",
      teams: ["t1", "t2"],
      fixtures: [{ match_id: "m-new", home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    assert.equal(dupLeague.status, 409);
    assert.equal(dupLeague.json.error.code, "LEAGUE_EXISTS");

    const dupMatch = await request("POST", "/audit/v1/leagues", {
      league_id: "lg-2",
      sport_id: "football",
      teams: ["t1", "t2"],
      fixtures: [{ match_id: "m1", home: "t1", away: "t2" }],
      qualification: { spots: 1 },
    });
    assert.equal(dupMatch.status, 409);
    assert.equal(dupMatch.json.error.code, "MATCH_EXISTS");

    const bad = await request("POST", "/audit/v1/leagues", { league_id: "x" });
    assert.equal(bad.status, 400);
    assert.equal(bad.json.error.code, "VALIDATION_ERROR");
  });

  it("initializes, starts, scores, and ends an event-model match with signatures", async () => {
    const init = await request("POST", "/audit/v1/events", {
      event_id: "evt-init-1",
      match_id: "m-event",
      type: "match_init",
      payload: { sport_id: "basketball", home_team_id: "t1", away_team_id: "t2" },
    });
    assert.equal(init.status, 201);
    assert.equal(init.json.sequence, 1);
    assert.equal(init.json.match_version, 1);
    assert.equal(
      init.json.signature,
      sign(SALT, "evt-init-1", { sport_id: "basketball", home_team_id: "t1", away_team_id: "t2" })
    );

    const replay = await request("POST", "/audit/v1/events", {
      event_id: "evt-init-1",
      match_id: "m-event",
      type: "match_init",
      payload: { sport_id: "basketball", home_team_id: "t1", away_team_id: "t2" },
    });
    assert.equal(replay.status, 200);
    assert.deepEqual(replay.json, init.json);

    const conflict = await request("POST", "/audit/v1/events", {
      event_id: "evt-init-1",
      match_id: "m-event",
      type: "match_init",
      payload: { sport_id: "basketball", home_team_id: "t1", away_team_id: "t9" },
    });
    assert.equal(conflict.status, 409);
    assert.equal(conflict.json.error.code, "DUPLICATE_EVENT_ID");

    const scoreEarly = await request("POST", "/audit/v1/events", {
      event_id: "evt-early",
      match_id: "m-event",
      type: "score",
      payload: { team_id: "t1", event_type: "two_pointer" },
    });
    assert.equal(scoreEarly.status, 409);
    assert.equal(scoreEarly.json.error.code, "MATCH_NOT_IN_PROGRESS");

    const start = await request("POST", "/audit/v1/events", {
      event_id: "evt-start-1",
      match_id: "m-event",
      type: "match_start",
      payload: {},
    });
    assert.equal(start.status, 201);
    assert.equal(start.json.sequence, 2);

    const startAgain = await request("POST", "/audit/v1/events", {
      event_id: "evt-start-2",
      match_id: "m-event",
      type: "match_start",
      payload: {},
    });
    assert.equal(startAgain.status, 409);
    assert.equal(startAgain.json.error.code, "ILLEGAL_TRANSITION");

    const goal1 = await request("POST", "/audit/v1/events", {
      event_id: "evt-goal-1",
      match_id: "m-event",
      type: "score",
      payload: { team_id: "t1", event_type: "two_pointer" },
    });
    assert.equal(goal1.status, 201);
    assert.equal(goal1.json.signature, sign(SALT, "evt-goal-1", { team_id: "t1", event_type: "two_pointer" }));

    const unknown = await request("POST", "/audit/v1/events", {
      event_id: "evt-unknown",
      match_id: "m-event",
      type: "score",
      payload: { team_id: "t1", event_type: "touchdown" },
    });
    assert.equal(unknown.status, 400);
    assert.equal(unknown.json.error.code, "UNKNOWN_EVENT_TYPE");

    const awayGoal = await request("POST", "/audit/v1/events", {
      event_id: "evt-goal-2",
      match_id: "m-event",
      type: "score",
      payload: { team_id: "t2", event_type: "two_pointer" },
    });
    assert.equal(awayGoal.status, 201);

    const card = await request("POST", "/audit/v1/events", {
      event_id: "evt-card-1",
      match_id: "m-event",
      type: "discipline",
      payload: { team_id: "t2", points: -1 },
    });
    assert.equal(card.status, 201);

    const end = await request("POST", "/audit/v1/events", {
      event_id: "evt-end-1",
      match_id: "m-event",
      type: "match_end",
      payload: {},
    });
    assert.equal(end.status, 409);
    assert.equal(end.json.error.code, "TIE_NOT_ALLOWED");

    const goal3 = await request("POST", "/audit/v1/events", {
      event_id: "evt-goal-3",
      match_id: "m-event",
      type: "score",
      payload: { team_id: "t1", event_type: "two_pointer" },
    });
    assert.equal(goal3.status, 201);

    const finished = await request("POST", "/audit/v1/events", {
      event_id: "evt-end-2",
      match_id: "m-event",
      type: "match_end",
      payload: {},
    });
    assert.equal(finished.status, 201);

    const score = await request("GET", "/audit/v1/score/m-event");
    assert.equal(score.status, 200);
    assert.equal(score.json.status, "completed");
    assert.equal(score.json.outcome, "home_win");
    assert.equal(score.json.winner_team_id, "t1");
    assert.equal(score.json.home.score, 4);
    assert.equal(score.json.away.score, 2);
    assert.equal(score.json.away.fair_play, -1);
    assert.equal(score.json.home.wickets, null);
    assert.equal(score.json.version, 7);
    assert.equal(score.json.events.length, 7);
  });

  it("compensates a score without deleting history", async () => {
    await request("POST", "/audit/v1/events", {
      event_id: "c-init",
      match_id: "m-comp",
      type: "match_init",
      payload: { sport_id: "football", home_team_id: "t1", away_team_id: "t2" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "c-start",
      match_id: "m-comp",
      type: "match_start",
      payload: {},
    });
    await request("POST", "/audit/v1/events", {
      event_id: "c-goal",
      match_id: "m-comp",
      type: "score",
      payload: { team_id: "t1", event_type: "goal" },
    });
    const comp = await request("POST", "/audit/v1/events", {
      event_id: "c-comp",
      match_id: "m-comp",
      type: "compensation",
      payload: { compensates: "c-goal", reason: "offside" },
    });
    assert.equal(comp.status, 201);
    const again = await request("POST", "/audit/v1/events", {
      event_id: "c-comp-2",
      match_id: "m-comp",
      type: "compensation",
      payload: { compensates: "c-goal", reason: "again" },
    });
    assert.equal(again.status, 409);
    assert.equal(again.json.error.code, "INVALID_COMPENSATION");

    const score = await request("GET", "/audit/v1/score/m-comp");
    assert.equal(score.json.home.score, 0);
    const original = score.json.events.find((event) => event.event_id === "c-goal");
    assert.equal(original.compensated, true);
    assert.equal(original.compensated_by, "c-comp");
  });

  it("scores innings and round sports from config", async () => {
    await request("POST", "/audit/v1/events", {
      event_id: "inn-init",
      match_id: "m-inn",
      type: "match_init",
      payload: { sport_id: "cricket", home_team_id: "t1", away_team_id: "t2" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "inn-start",
      match_id: "m-inn",
      type: "match_start",
      payload: {},
    });
    await request("POST", "/audit/v1/events", {
      event_id: "inn-four",
      match_id: "m-inn",
      type: "score",
      payload: { team_id: "t1", event_type: "four" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "inn-wide",
      match_id: "m-inn",
      type: "score",
      payload: { team_id: "t1", event_type: "wide" },
    });
    const inn = await request("GET", "/audit/v1/score/m-inn");
    assert.equal(inn.json.home.score, 5);
    assert.equal(inn.json.home.balls, 1);
    assert.equal(inn.json.home.overs, "0.1");
    assert.equal(inn.json.home.wickets, 0);

    await request("POST", "/audit/v1/events", {
      event_id: "rd-init",
      match_id: "m-rd",
      type: "match_init",
      payload: { sport_id: "esports", home_team_id: "t1", away_team_id: "t2" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "rd-start",
      match_id: "m-rd",
      type: "match_start",
      payload: {},
    });
    await request("POST", "/audit/v1/events", {
      event_id: "rd-1",
      match_id: "m-rd",
      type: "score",
      payload: { team_id: "t1", event_type: "round_win" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "rd-2",
      match_id: "m-rd",
      type: "score",
      payload: { team_id: "t1", event_type: "round_win" },
    });
    const decided = await request("POST", "/audit/v1/events", {
      event_id: "rd-3",
      match_id: "m-rd",
      type: "score",
      payload: { team_id: "t1", event_type: "round_win" },
    });
    assert.equal(decided.status, 409);
    assert.equal(decided.json.error.code, "SERIES_ALREADY_DECIDED");
  });

  it("accepts concurrent score events without losing versions", async () => {
    await request("POST", "/audit/v1/events", {
      event_id: "par-init",
      match_id: "m-par",
      type: "match_init",
      payload: { sport_id: "football", home_team_id: "t1", away_team_id: "t2" },
    });
    await request("POST", "/audit/v1/events", {
      event_id: "par-start",
      match_id: "m-par",
      type: "match_start",
      payload: {},
    });
    const results = await Promise.all(
      [1, 2, 3, 4, 5].map((n) =>
        request("POST", "/audit/v1/events", {
          event_id: `par-goal-${n}`,
          match_id: "m-par",
          type: "score",
          payload: { team_id: n % 2 === 0 ? "t2" : "t1", event_type: "goal" },
        })
      )
    );
    assert.ok(results.every((res) => res.status === 201));
    const versions = results.map((res) => res.json.match_version).sort((a, b) => a - b);
    assert.deepEqual(versions, [3, 4, 5, 6, 7]);
    const score = await request("GET", "/audit/v1/score/m-par");
    assert.equal(score.json.home.score + score.json.away.score, 5);
    assert.equal(score.json.version, 7);
  });

  it("returns 404 for unknown matches and missing events", async () => {
    const missingMatch = await request("POST", "/audit/v1/events", {
      event_id: "no-match",
      match_id: "missing-match",
      type: "match_start",
      payload: {},
    });
    assert.equal(missingMatch.status, 404);
    assert.equal(missingMatch.json.error.code, "MATCH_NOT_FOUND");

    const missingScore = await request("GET", "/audit/v1/score/missing-match");
    assert.equal(missingScore.status, 404);

    const missingEvent = await request("POST", "/audit/v1/events", {
      event_id: "bad-comp",
      match_id: "m-par",
      type: "compensation",
      payload: { compensates: "does-not-exist", reason: "x" },
    });
    assert.equal(missingEvent.status, 404);
    assert.equal(missingEvent.json.error.code, "EVENT_NOT_FOUND");
  });
});
