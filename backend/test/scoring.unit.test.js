const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { projectMatch, validateEventBody } = require("../src/scoring");

const football = {
  scoring_model: "event",
  draw_allowed: true,
  scoring_events: { goal: { points: 1 } },
  periods: { count: 2 },
};

const cricket = {
  scoring_model: "innings",
  draw_allowed: true,
  scoring_events: {
    four: { runs: 4, legal_ball: true, wicket: false },
    wicket: { runs: 0, legal_ball: true, wicket: true },
  },
  periods: { balls_per_over: 6, overs_per_innings: 20, wickets_per_innings: 10, innings_per_team: 1 },
};

const esports = {
  scoring_model: "round",
  draw_allowed: false,
  scoring_events: { round_win: { rounds: 1 } },
  periods: { best_of: 3 },
};

describe("scoring projections", () => {
  it("projects an event-model completed win", () => {
    const projection = projectMatch(
      { home_team_id: "t1", away_team_id: "t2" },
      football,
      [
        { event_id: "s", type: "match_start", payload: {} },
        { event_id: "g", type: "score", payload: { team_id: "t1", event_type: "goal" } },
        { event_id: "e", type: "match_end", payload: {} },
      ]
    );
    assert.equal(projection.status, "completed");
    assert.equal(projection.outcome, "home_win");
    assert.equal(projection.home.score, 1);
    assert.equal(projection.away.score, 0);
  });

  it("compensates a score event and leaves an in-progress draw", () => {
    const projection = projectMatch(
      { home_team_id: "t1", away_team_id: "t2" },
      football,
      [
        { event_id: "s", type: "match_start", payload: {} },
        { event_id: "g", type: "score", payload: { team_id: "t1", event_type: "goal" } },
        { event_id: "c", type: "compensation", payload: { compensates: "g" } },
      ]
    );
    assert.equal(projection.status, "in_progress");
    assert.equal(projection.home.score, 0);
    assert.equal(projection.outcome, "pending");
  });

  it("counts innings runs, legal balls and wickets", () => {
    const projection = projectMatch(
      { home_team_id: "t1", away_team_id: "t2" },
      cricket,
      [
        { event_id: "s", type: "match_start", payload: {} },
        { event_id: "f", type: "score", payload: { team_id: "t1", event_type: "four" } },
        { event_id: "w", type: "score", payload: { team_id: "t1", event_type: "wicket" } },
      ]
    );
    assert.equal(projection.home.score, 4);
    assert.equal(projection.home.wickets, 1);
    assert.equal(projection.home.balls, 2);
    assert.equal(projection.home.overs, "0.2");
  });

  it("uses tiebreak winner when scores are level", () => {
    const projection = projectMatch(
      { home_team_id: "t1", away_team_id: "t2" },
      esports,
      [
        { event_id: "s", type: "match_start", payload: {} },
        { event_id: "r1", type: "score", payload: { team_id: "t1", event_type: "round_win" } },
        { event_id: "r2", type: "score", payload: { team_id: "t2", event_type: "round_win" } },
        { event_id: "tb", type: "tiebreak_winner", payload: { team_id: "t2" } },
        { event_id: "e", type: "match_end", payload: {} },
      ]
    );
    assert.equal(projection.outcome, "away_win");
    assert.equal(projection.winner_team_id, "t2");
  });

  it("rejects invalid event bodies", () => {
    assert.equal(validateEventBody({}).ok, false);
    assert.equal(validateEventBody({ event_id: "e1", match_id: "m1", type: "score", payload: {} }).ok, false);
  });
});
