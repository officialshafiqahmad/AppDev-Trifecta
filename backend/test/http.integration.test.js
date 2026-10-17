const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");

const BASE = process.env.AUDIT_BASE_URL || "http://127.0.0.1:8080";

async function request(method, path, body) {
  const headers = {};
  const options = { method, headers };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    options.body = typeof body === "string" ? body : JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (_err) {
    json = text;
  }
  return { status: res.status, json };
}

describe("live Module 1 HTTP contracts", { skip: process.env.SKIP_HTTP === "1" }, () => {
  before(async () => {
    const health = await request("GET", "/health");
    if (health.status !== 200) {
      throw new Error(`API not ready at ${BASE}: ${health.status}`);
    }
  });

  it("GET /health returns the official body", async () => {
    const res = await request("GET", "/health");
    assert.equal(res.status, 200);
    assert.deepEqual(res.json, { status: "ok" });
  });

  it("POST /audit/v1/reset is repeatable with official defaults", async () => {
    const first = await request("POST", "/audit/v1/reset", {});
    const second = await request("POST", "/audit/v1/reset", {});
    const expected = {
      status: "reset_complete",
      seed: 42,
      sports: ["football", "basketball", "cricket", "esports"],
      tenants: ["tenant-alpha", "tenant-beta"],
      stock: { "var-jersey-001-M": 1, "var-jersey-001-L": 5 },
    };
    assert.equal(first.status, 200);
    assert.equal(second.status, 200);
    assert.deepEqual(first.json, expected);
    assert.deepEqual(second.json, expected);
  });

  it("POST /audit/v1/sports creates, conflicts, and validates", async () => {
    await request("POST", "/audit/v1/reset", {});
    const created = await request("POST", "/audit/v1/sports", {
      sport_id: "kabaddi",
      name: "Kabaddi",
      scoring_model: "event",
      periods: { count: 2, duration_minutes: 20 },
      scoring_events: { raid_point: { points: 1 } },
      draw_allowed: false,
      overtime: { policy: "golden_score", duration_minutes: 5 },
      roster: { min_squad_size: 7, max_squad_size: 12, required_positions: {} },
    });
    assert.equal(created.status, 201);
    assert.equal(created.json.status, "created");
    assert.equal(created.json.sport_id, "kabaddi");

    const dup = await request("POST", "/audit/v1/sports", created.json.config);
    assert.equal(dup.status, 409);
    assert.equal(dup.json.error.code, "SPORT_EXISTS");

    const football = await request("POST", "/audit/v1/sports", {
      sport_id: "football",
      name: "Football",
      scoring_model: "event",
      periods: { count: 2, duration_minutes: 45 },
      scoring_events: { goal: { points: 1 } },
      draw_allowed: true,
      overtime: { policy: "none" },
      roster: { min_squad_size: 11, max_squad_size: 25, required_positions: { gk: 1 } },
    });
    assert.equal(football.status, 409);

    const bad = await request("POST", "/audit/v1/sports", { sport_id: "X" });
    assert.equal(bad.status, 400);
    assert.equal(bad.json.error.code, "VALIDATION_ERROR");
    assert.ok(Array.isArray(bad.json.error.details.fields));
  });

  it("rejects bodies larger than 1 MB with 413", async () => {
    const huge = JSON.stringify({ seed: 1, pad: "x".repeat(1024 * 1024) });
    const res = await request("POST", "/audit/v1/reset", huge);
    assert.equal(res.status, 413);
    assert.equal(res.json.error.code, "PAYLOAD_TOO_LARGE");
  });
});
