const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { oversFaced, roundNrr, getStandings } = require("../src/standings");

function mockPool(handlers) {
  return {
    async query(sql) {
      if (sql.includes("FROM leagues")) return handlers.league;
      if (sql.includes("FROM sports")) return handlers.sport;
      if (sql.includes("FROM matches")) return handlers.matches;
      if (sql.includes("match_events")) return handlers.events;
      return { rowCount: 0, rows: [] };
    },
  };
}

describe("standings helpers", () => {
  it("uses full overs when a side is all out", () => {
    const overs = oversFaced(
      { wickets: 10, balls: 17 },
      { periods: { innings_per_team: 1, wickets_per_innings: 10, overs_per_innings: 20, balls_per_over: 6 } }
    );
    assert.equal(overs, 20);
  });

  it("converts legal balls into fractional overs", () => {
    const overs = oversFaced(
      { wickets: 2, balls: 4 },
      { periods: { innings_per_team: 1, wickets_per_innings: 10, overs_per_innings: 20, balls_per_over: 6 } }
    );
    assert.equal(overs, 4 / 6);
  });

  it("rounds NRR to three decimals and maps non-finite values to 0", () => {
    assert.equal(roundNrr(24.0004), 24);
    assert.equal(roundNrr(1.2346), 1.235);
    assert.equal(roundNrr(Number.POSITIVE_INFINITY), 0);
    assert.equal(roundNrr(Number.NaN), 0);
  });

  it("returns official 404 for an unknown league", async () => {
    const result = await getStandings(mockPool({
      league: { rowCount: 0, rows: [] },
    }), "no-such-league");
    assert.equal(result.error.code, "LEAGUE_NOT_FOUND");
  });

  it("rebuilds an empty table and a completed event-model result", async () => {
    const empty = await getStandings(mockPool({
      league: { rowCount: 1, rows: [{ league_id: "lg-empty", sport_id: "football", config: { teams: ["t1", "t2"], qualification: { spots: 1 } } }] },
      sport: { rowCount: 1, rows: [{ config: { scoring_model: "event", scoring_events: { goal: { points: 1 } }, draw_allowed: true } }] },
      matches: { rowCount: 0, rows: [] },
      events: { rowCount: 0, rows: [] },
    }), "lg-empty");
    assert.equal(empty.body.table.length, 2);
    assert.equal(empty.body.h2h.t1.t2.played, 0);

    const completed = await getStandings(mockPool({
      league: {
        rowCount: 1,
        rows: [{
          league_id: "lg-1",
          sport_id: "football",
          config: {
            teams: ["t1", "t2", "t3"],
            points: { win: 3, draw: 1, loss: 0 },
            qualification: { spots: 1 },
            lots_seed: 42,
          },
        }],
      },
      sport: { rowCount: 1, rows: [{ config: { scoring_model: "event", scoring_events: { goal: { points: 1 } }, draw_allowed: true } }] },
      matches: {
        rowCount: 1,
        rows: [{ match_id: "m1", league_id: "lg-1", home_team_id: "t1", away_team_id: "t2" }],
      },
      events: {
        rowCount: 3,
        rows: [
          { match_id: "m1", event_id: "s", type: "match_start", payload: {}, sequence: 1 },
          { match_id: "m1", event_id: "g", type: "score", payload: { team_id: "t1", event_type: "goal" }, sequence: 2 },
          { match_id: "m1", event_id: "e", type: "match_end", payload: {}, sequence: 3 },
        ],
      },
    }), "lg-1");
    assert.equal(completed.body.table[0].team_id, "t1");
    assert.equal(completed.body.table[0].points, 3);
    assert.equal(completed.body.table[0].status, "clinched");
    assert.equal(completed.body.table[1].status, "eliminated");
    assert.equal(completed.body.h2h.t1.t2.played, 1);
  });
});
