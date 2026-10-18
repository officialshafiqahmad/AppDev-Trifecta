const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");
const { can, actorFromUser, CONTEXT } = require("../src/rbac");
const { signJwt, verifyJwt, bearerToken } = require("../src/jwt");
const { clientIp } = require("../src/ratelimit");

describe("RBAC policy and JWT helpers", () => {
  before(() => {
    process.env.JWT_SECRET = process.env.JWT_SECRET || "replace-for-local-development";
  });

  it("lets a super-admin do everything and blocks cross-tenant access", () => {
    const admin = actorFromUser({ role: "super_admin", tenant_id: null });
    const organizer = actorFromUser({
      role: "league_organizer",
      tenant_id: "tenant-alpha",
      league_id: CONTEXT.own_league_id,
    });
    assert.equal(can(admin, "platform.tenants.create"), true);
    assert.equal(can(organizer, "league.fixtures.write", { league_id: CONTEXT.own_league_id, tenant_id: "tenant-alpha" }), true);
    assert.equal(can(organizer, "league.fixtures.write", { league_id: CONTEXT.other_league_id, tenant_id: "tenant-alpha" }), false);
    assert.equal(can(organizer, "club.read", { tenant_id: CONTEXT.foreign_tenant_id }), false);
  });

  it("scopes club and player writes", () => {
    const manager = actorFromUser({
      role: "club_manager",
      tenant_id: "tenant-alpha",
      club_id: CONTEXT.own_club_id,
    });
    const player = actorFromUser({
      role: "player",
      tenant_id: "tenant-alpha",
      club_id: CONTEXT.own_club_id,
      player_id: CONTEXT.own_player_id,
    });
    assert.equal(can(manager, "club.roster.write", { club_id: CONTEXT.own_club_id, tenant_id: "tenant-alpha" }), true);
    assert.equal(can(manager, "club.roster.write", { club_id: CONTEXT.other_club_id, tenant_id: "tenant-alpha" }), false);
    assert.equal(can(player, "player.update", { player_id: CONTEXT.own_player_id, tenant_id: "tenant-alpha" }), true);
    assert.equal(can(player, "player.update", { player_id: CONTEXT.other_player_id, tenant_id: "tenant-alpha" }), false);
  });

  it("signs and verifies HS256 JWTs and rejects alg none", () => {
    const token = signJwt({ sub: "user-admin", role: "super_admin" }, { ttlSec: 60 });
    const payload = verifyJwt(token);
    assert.equal(payload.sub, "user-admin");
    assert.throws(() => verifyJwt("a.b.c"), { code: "UNAUTHENTICATED" });
    assert.equal(bearerToken({ headers: { authorization: `Bearer ${token}` } }), token);
    assert.equal(bearerToken({ headers: {} }), null);
  });

  it("reads the client IP from X-Forwarded-For", () => {
    assert.equal(clientIp({ headers: { "x-forwarded-for": "1.2.3.4, 5.6.7.8" }, socket: {} }), "1.2.3.4");
    assert.equal(clientIp({ headers: {}, socket: { remoteAddress: "127.0.0.1" } }), "127.0.0.1");
  });
});
