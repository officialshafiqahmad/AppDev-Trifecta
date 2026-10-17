const { signJwt, verifyJwt, bearerToken } = require("./jwt");
const { sendError } = require("./errors");

const CONTEXT = {
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
};

const ROLE_CLAIM = {
  super_admin: "super_admin",
  league_organizer: "league_organizer",
  club_manager: "club_manager",
  player: "player",
  viewer: "viewer",
};

function actorFromUser(user) {
  return {
    role: user.role,
    tenant_id: user.tenant_id || null,
    league_id: user.league_id || null,
    club_id: user.club_id || null,
    player_id: user.player_id || null,
  };
}

function can(actor, action, resource = {}) {
  if (actor.role === "super_admin") return true;
  if (resource.tenant_id && actor.tenant_id && resource.tenant_id !== actor.tenant_id) return false;

  switch (action) {
    case "platform.tenants.create":
    case "platform.config.read":
      return false;
    case "league.fixtures.write":
      return actor.role === "league_organizer" && actor.league_id === resource.league_id;
    case "club.roster.write":
    case "club.products.write":
      return actor.role === "club_manager" && actor.club_id === resource.club_id;
    case "player.update":
      if (actor.role === "club_manager") return actor.club_id === resource.club_id;
      if (actor.role === "player") return actor.player_id === resource.player_id;
      return false;
    case "club.read":
      return Boolean(actor.tenant_id && resource.tenant_id && actor.tenant_id === resource.tenant_id);
    default:
      return false;
  }
}

async function issueMatrix(pool) {
  const users = await pool.query(
    "SELECT user_id, role, tenant_id, league_id, club_id, player_id FROM users"
  );
  const byRole = new Map(users.rows.map((row) => [row.role, row]));
  const tokens = {};
  for (const role of Object.keys(ROLE_CLAIM)) {
    const user = byRole.get(role);
    if (!user) throw new Error(`missing seeded user for ${role}`);
    tokens[role] = signJwt({
      sub: user.user_id,
      role: user.role,
      tenant_id: user.tenant_id,
      league_id: user.league_id,
      club_id: user.club_id,
      player_id: user.player_id,
    }, { ttlSec: 3600 });
  }
  return { tokens, context: CONTEXT };
}

function authenticate(req, res, next) {
  const token = bearerToken(req);
  if (!token) {
    sendError(res, 401, "UNAUTHENTICATED", "Missing or malformed bearer token.", {});
    return;
  }
  try {
    const payload = verifyJwt(token);
    req.actor = {
      role: payload.role,
      tenant_id: payload.tenant_id || null,
      league_id: payload.league_id || null,
      club_id: payload.club_id || null,
      player_id: payload.player_id || null,
    };
    next();
  } catch (_err) {
    sendError(res, 401, "UNAUTHENTICATED", "Invalid, tampered, or expired token.", {});
  }
}

function allow(action) {
  return (req, res) => {
    if (!can(req.actor, action)) {
      sendError(res, 403, "FORBIDDEN", "Role is not permitted for this action.", { action });
      return;
    }
    res.status(200).json({ authorized: true });
  };
}

async function loadLeague(pool, leagueId) {
  const result = await pool.query("SELECT league_id, tenant_id FROM leagues WHERE league_id = $1", [leagueId]);
  return result.rows[0] || null;
}

async function loadClub(pool, clubId) {
  const result = await pool.query("SELECT club_id, tenant_id FROM clubs WHERE club_id = $1", [clubId]);
  return result.rows[0] || null;
}

async function loadPlayer(pool, playerId) {
  const result = await pool.query(
    `SELECT players.player_id, players.club_id, clubs.tenant_id
     FROM players
     JOIN clubs ON clubs.club_id = players.club_id
     WHERE players.player_id = $1`,
    [playerId]
  );
  return result.rows[0] || null;
}

function authorizeEntity(action, loader, missingCode, missingField) {
  return async (req, res, next) => {
    try {
      const id = req.params[missingField];
      const resource = await loader(req.app.locals.pool, id);
      if (!resource) {
        sendError(res, 404, missingCode, `${missingField} ${id} was not found.`, { [missingField]: id });
        return;
      }
      if (!can(req.actor, action, resource)) {
        sendError(res, 403, "FORBIDDEN", "Role is not permitted for this resource.", {
          action,
          [missingField]: id,
        });
        return;
      }
      res.status(200).json({ authorized: true });
    } catch (error) {
      next(error);
    }
  };
}

function mountRbac(app, pool) {
  app.locals.pool = pool;

  app.post("/audit/v1/rbac-matrix", async (_req, res, next) => {
    try {
      res.status(200).json(await issueMatrix(pool));
    } catch (error) {
      next(error);
    }
  });

  app.post("/audit/v1/rbac/tenants", authenticate, allow("platform.tenants.create"));
  app.post(
    "/audit/v1/rbac/leagues/:league_id/fixtures",
    authenticate,
    authorizeEntity("league.fixtures.write", loadLeague, "LEAGUE_NOT_FOUND", "league_id")
  );
  app.post(
    "/audit/v1/rbac/clubs/:club_id/roster",
    authenticate,
    authorizeEntity("club.roster.write", loadClub, "CLUB_NOT_FOUND", "club_id")
  );
  app.post(
    "/audit/v1/rbac/clubs/:club_id/products",
    authenticate,
    authorizeEntity("club.products.write", loadClub, "CLUB_NOT_FOUND", "club_id")
  );
  app.patch(
    "/audit/v1/rbac/players/:player_id",
    authenticate,
    authorizeEntity("player.update", loadPlayer, "PLAYER_NOT_FOUND", "player_id")
  );
  app.get(
    "/audit/v1/rbac/clubs/:club_id",
    authenticate,
    authorizeEntity("club.read", loadClub, "CLUB_NOT_FOUND", "club_id")
  );
  app.get("/audit/v1/rbac/platform/config", authenticate, allow("platform.config.read"));
}

module.exports = { mountRbac, can, actorFromUser, CONTEXT };
