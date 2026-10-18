const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");
const { signJwt } = require("../src/jwt");

process.env.JWT_SECRET = process.env.JWT_SECRET || "replace-for-local-development";

const BASE = process.env.AUDIT_BASE_URL || "http://127.0.0.1:8080";

async function request(method, path, { token, body } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const options = { method, headers };
  if (body !== undefined && method !== "GET" && method !== "HEAD") {
    headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (_err) {
    json = text;
  }
  return { status: res.status, json, headers: res.headers };
}

function noneAlg(payload) {
  const header = Buffer.from(JSON.stringify({ alg: "none", typ: "JWT" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${header}.${body}.`;
}

describe("Module 4 RBAC and rate limiting", { skip: process.env.SKIP_HTTP === "1" }, () => {
  let tokens;
  let context;
  let sportsBefore;

  before(async () => {
    const health = await request("GET", "/health");
    if (health.status !== 200) throw new Error("API not ready");
    await request("POST", "/audit/v1/reset", { body: {} });
    const matrix = await request("POST", "/audit/v1/rbac-matrix");
    assert.equal(matrix.status, 200);
    tokens = matrix.json.tokens;
    context = matrix.json.context;
    const sport = await request("POST", "/audit/v1/sports", {
      body: {
        sport_id: "rbac-probe-sport",
        name: "Probe",
        scoring_model: "event",
        periods: { count: 1, duration_minutes: 1 },
        scoring_events: { point: { points: 1 } },
        draw_allowed: true,
        overtime: { policy: "none" },
        roster: { min_squad_size: 1, max_squad_size: 2, required_positions: {} },
      },
    });
    sportsBefore = sport.status;
  });

  it("returns five JWTs and the official context", async () => {
    assert.deepEqual(Object.keys(tokens).sort(), ["club_manager", "league_organizer", "player", "super_admin", "viewer"]);
    assert.deepEqual(context, {
      tenant_id: "tenant-alpha",
      foreign_tenant_id: "tenant-beta",
      own_league_id: "league-alpha-1",
      other_league_id: "league-alpha-2",
      foreign_league_id: "league-beta-1",
      own_club_id: "club-alpha-1",
      other_club_id: "club-alpha-2",
      foreign_club_id: "club-beta-1",
      own_player_id: "player-alpha-1",
      other_player_id: "player-alpha-2",
      foreign_player_id: "player-beta-1",
    });
    for (const token of Object.values(tokens)) {
      assert.equal(token.split(".").length, 3);
    }
  });

  it("enforces the official P1-P7 authorization matrix", async () => {
    const cases = [
      ["P1", "POST", "/audit/v1/rbac/tenants", ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P2 own", "POST", `/audit/v1/rbac/leagues/${context.own_league_id}/fixtures`, ["super_admin", "league_organizer"], ["club_manager", "player", "viewer"]],
      ["P2 other", "POST", `/audit/v1/rbac/leagues/${context.other_league_id}/fixtures`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P2 foreign", "POST", `/audit/v1/rbac/leagues/${context.foreign_league_id}/fixtures`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P3 own", "POST", `/audit/v1/rbac/clubs/${context.own_club_id}/roster`, ["super_admin", "club_manager"], ["league_organizer", "player", "viewer"]],
      ["P3 other", "POST", `/audit/v1/rbac/clubs/${context.other_club_id}/roster`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P3 foreign", "POST", `/audit/v1/rbac/clubs/${context.foreign_club_id}/roster`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P4 own", "POST", `/audit/v1/rbac/clubs/${context.own_club_id}/products`, ["super_admin", "club_manager"], ["league_organizer", "player", "viewer"]],
      ["P4 other", "POST", `/audit/v1/rbac/clubs/${context.other_club_id}/products`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P5 own player", "PATCH", `/audit/v1/rbac/players/${context.own_player_id}`, ["super_admin", "club_manager", "player"], ["league_organizer", "viewer"]],
      ["P5 other player", "PATCH", `/audit/v1/rbac/players/${context.other_player_id}`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P5 foreign player", "PATCH", `/audit/v1/rbac/players/${context.foreign_player_id}`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P6 own", "GET", `/audit/v1/rbac/clubs/${context.own_club_id}`, ["super_admin", "league_organizer", "club_manager", "player", "viewer"], []],
      ["P6 other", "GET", `/audit/v1/rbac/clubs/${context.other_club_id}`, ["super_admin", "league_organizer", "club_manager", "player", "viewer"], []],
      ["P6 foreign", "GET", `/audit/v1/rbac/clubs/${context.foreign_club_id}`, ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
      ["P7", "GET", "/audit/v1/rbac/platform/config", ["super_admin"], ["league_organizer", "club_manager", "player", "viewer"]],
    ];

    for (const [, method, path, allowed, denied] of cases) {
      for (const role of allowed) {
        const res = await request(method, path, { token: tokens[role], body: {} });
        assert.equal(res.status, 200, `${role} ${method} ${path}`);
        assert.deepEqual(res.json, { authorized: true });
      }
      for (const role of denied) {
        const res = await request(method, path, { token: tokens[role], body: {} });
        assert.equal(res.status, 403, `${role} ${method} ${path}`);
        assert.equal(res.json.error.code, "FORBIDDEN");
      }
    }
  });

  it("rejects missing, tampered, alg:none and expired tokens", async () => {
    const missing = await request("GET", "/audit/v1/rbac/platform/config");
    assert.equal(missing.status, 401);
    assert.equal(missing.json.error.code, "UNAUTHENTICATED");

    const tampered = `${tokens.super_admin.slice(0, -2)}aa`;
    const badSig = await request("GET", "/audit/v1/rbac/platform/config", { token: tampered });
    assert.equal(badSig.status, 401);
    assert.equal(badSig.json.error.code, "UNAUTHENTICATED");

    const none = noneAlg({ role: "super_admin", exp: Math.floor(Date.now() / 1000) + 3600 });
    const noneRes = await request("GET", "/audit/v1/rbac/platform/config", { token: none });
    assert.equal(noneRes.status, 401);

    const expired = signJwt({ role: "super_admin" }, { exp: Math.floor(Date.now() / 1000) - 10 });
    const expiredRes = await request("GET", "/audit/v1/rbac/platform/config", { token: expired });
    assert.equal(expiredRes.status, 401);
  });

  it("returns 404 for unknown ids and does not mutate domain data", async () => {
    const league = await request("POST", "/audit/v1/rbac/leagues/no-such-league/fixtures", { token: tokens.super_admin, body: {} });
    assert.equal(league.status, 404);
    assert.equal(league.json.error.code, "LEAGUE_NOT_FOUND");
    const player = await request("PATCH", "/audit/v1/rbac/players/no-such-player", { token: tokens.super_admin, body: {} });
    assert.equal(player.status, 404);
    assert.equal(player.json.error.code, "PLAYER_NOT_FOUND");
    const club = await request("GET", "/audit/v1/rbac/clubs/no-such-club", { token: tokens.super_admin });
    assert.equal(club.status, 404);

    const again = await request("POST", "/audit/v1/sports", {
      body: {
        sport_id: "rbac-probe-sport",
        name: "Probe",
        scoring_model: "event",
        periods: { count: 1, duration_minutes: 1 },
        scoring_events: { point: { points: 1 } },
        draw_allowed: true,
        overtime: { policy: "none" },
        roster: { min_squad_size: 1, max_squad_size: 2, required_positions: {} },
      },
    });
    assert.equal(again.status, 409);
    assert.equal(sportsBefore, 201);
  });

  it("rate-limits /api/v1/ping and recovers after the window", async () => {
    const results = await Promise.all(Array.from({ length: 150 }, () => request("GET", "/api/v1/ping")));
    const limited = results.filter((res) => res.status === 429 && res.json.error && res.json.error.code === "RATE_LIMITED");
    assert.ok(limited.length >= 40, `expected >=40 429, got ${limited.length} of ${results.length}`);
    assert.ok(limited.every((res) => res.headers.get("retry-after")));
    await new Promise((resolve) => setTimeout(resolve, 11000));
    const later = await request("GET", "/api/v1/ping");
    assert.equal(later.status, 200);
    assert.deepEqual(later.json, { pong: true });
  });
});
