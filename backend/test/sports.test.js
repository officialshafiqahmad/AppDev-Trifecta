const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { validateSport } = require("../src/sports");

const eventSport = {
  sport_id: "kabaddi",
  name: "Kabaddi",
  scoring_model: "event",
  periods: { count: 2, duration_minutes: 20 },
  scoring_events: {
    raid_point: { points: 1 },
    tackle_point: { points: 1 },
    all_out: { points: 2 },
  },
  draw_allowed: false,
  overtime: { policy: "golden_score", duration_minutes: 5 },
  tie_break_order: ["h2h_points", "h2h_diff", "overall_diff", "scored", "fair_play", "draw_lots"],
  roster: { min_squad_size: 7, max_squad_size: 12, required_positions: { raider: 2, defender: 3 } },
};

describe("mystery sport validation", () => {
  it("accepts the official event-model example", () => {
    const result = validateSport(eventSport);
    assert.equal(result.config.sport_id, "kabaddi");
    assert.deepEqual(result.config.tie_break_order[result.config.tie_break_order.length - 1], "draw_lots");
  });

  it("accepts innings and round fragments", () => {
    const innings = validateSport({
      sport_id: "tape-ball",
      name: "Tape Ball",
      scoring_model: "innings",
      periods: { innings_per_team: 1, overs_per_innings: 10, balls_per_over: 6, wickets_per_innings: 10 },
      scoring_events: {
        super_six: { runs: 6, legal_ball: true, wicket: false },
        bye_run: { runs: 1, legal_ball: false, wicket: false },
        out: { runs: 0, legal_ball: true, wicket: true },
      },
      draw_allowed: true,
      overtime: { policy: "super_over" },
      roster: { min_squad_size: 6, max_squad_size: 11, required_positions: {} },
    });
    assert.equal(innings.config.scoring_model, "innings");

    const round = validateSport({
      sport_id: "valorant",
      name: "Valorant",
      scoring_model: "round",
      periods: { best_of: 5 },
      scoring_events: { map_win: { rounds: 1 } },
      draw_allowed: false,
      overtime: { policy: "none" },
      roster: { min_squad_size: 5, max_squad_size: 5, required_positions: {} },
    });
    assert.equal(round.config.periods.best_of, 5);
  });

  it("rejects even best_of and missing fields", () => {
    const badRound = validateSport({
      ...eventSport,
      sport_id: "bo4",
      scoring_model: "round",
      periods: { best_of: 4 },
      scoring_events: { map_win: { rounds: 1 } },
    });
    assert.ok(badRound.fields.includes("periods.best_of") || badRound.fields.includes("periods"));

    const missing = validateSport({ sport_id: "x" });
    assert.ok(missing.fields.includes("sport_id"));
    assert.ok(missing.fields.includes("name"));
  });
});
