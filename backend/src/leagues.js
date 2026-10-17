const { TIE_BREAKS } = require("./sports");

const ID_RE = /^[A-Za-z0-9_.:-]{1,64}$/;
const TIE_SET = new Set(TIE_BREAKS);

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isInt(value) {
  return typeof value === "number" && Number.isInteger(value);
}

function validateId(value) {
  return typeof value === "string" && ID_RE.test(value) && !value.includes("|");
}

function validateTieBreak(order) {
  if (!Array.isArray(order) || order.length === 0) return null;
  const seen = new Set();
  for (const item of order) {
    if (typeof item !== "string" || !TIE_SET.has(item) || seen.has(item)) return null;
    seen.add(item);
  }
  const withoutLots = order.filter((item) => item !== "draw_lots");
  return withoutLots.concat("draw_lots");
}

function validateLeague(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ["body"] };
  const fields = [];

  if (!validateId(body.league_id)) fields.push("league_id");
  if (!validateId(body.sport_id)) fields.push("sport_id");

  if (!Array.isArray(body.teams) || body.teams.length < 2 || body.teams.length > 40) {
    fields.push("teams");
  } else {
    const seen = new Set();
    for (const team of body.teams) {
      if (!validateId(team) || seen.has(team)) {
        fields.push("teams");
        break;
      }
      seen.add(team);
    }
  }

  if (!Array.isArray(body.fixtures)) {
    fields.push("fixtures");
  } else {
    const matchIds = new Set();
    const teamSet = Array.isArray(body.teams) ? new Set(body.teams) : new Set();
    body.fixtures.forEach((fixture, index) => {
      if (!isPlainObject(fixture) || !validateId(fixture.match_id) || !validateId(fixture.home) || !validateId(fixture.away)) {
        fields.push(`fixtures.${index}`);
        return;
      }
      if (fixture.home === fixture.away || !teamSet.has(fixture.home) || !teamSet.has(fixture.away) || matchIds.has(fixture.match_id)) {
        fields.push(`fixtures.${index}`);
        return;
      }
      matchIds.add(fixture.match_id);
    });
  }

  let points = { win: 3, draw: 1, loss: 0 };
  if (Object.prototype.hasOwnProperty.call(body, "points")) {
    if (!isPlainObject(body.points)) fields.push("points");
    else {
      points = {
        win: Object.prototype.hasOwnProperty.call(body.points, "win") ? body.points.win : 3,
        draw: Object.prototype.hasOwnProperty.call(body.points, "draw") ? body.points.draw : 1,
        loss: Object.prototype.hasOwnProperty.call(body.points, "loss") ? body.points.loss : 0,
      };
      if (!isInt(points.win) || !isInt(points.draw) || !isInt(points.loss)) fields.push("points");
    }
  }

  if (!isPlainObject(body.qualification) || !isInt(body.qualification.spots)) {
    fields.push("qualification");
  } else if (Array.isArray(body.teams) && (body.qualification.spots < 1 || body.qualification.spots > body.teams.length)) {
    fields.push("qualification.spots");
  }

  if (Object.prototype.hasOwnProperty.call(body, "lots_seed") && !isInt(body.lots_seed)) {
    fields.push("lots_seed");
  }

  let tieBreakOrder = null;
  if (Object.prototype.hasOwnProperty.call(body, "tie_break_order")) {
    tieBreakOrder = validateTieBreak(body.tie_break_order);
    if (!tieBreakOrder) fields.push("tie_break_order");
  }

  if (fields.length > 0) return { ok: false, fields };

  return {
    ok: true,
    league: {
      league_id: body.league_id,
      sport_id: body.sport_id,
      teams: body.teams.slice(),
      fixtures: body.fixtures.map((fixture) => ({
        match_id: fixture.match_id,
        home: fixture.home,
        away: fixture.away,
      })),
      points,
      qualification: { spots: body.qualification.spots },
      lots_seed: Object.prototype.hasOwnProperty.call(body, "lots_seed") ? body.lots_seed : null,
      tie_break_order: tieBreakOrder,
    },
  };
}

async function createLeague(pool, league) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const sport = await client.query("SELECT sport_id, config FROM sports WHERE sport_id = $1", [league.sport_id]);
    if (sport.rowCount === 0) {
      await client.query("ROLLBACK");
      return { error: { status: 404, code: "SPORT_NOT_FOUND", message: `Sport ${league.sport_id} was not found.`, details: { sport_id: league.sport_id } } };
    }

    const existingLeague = await client.query("SELECT league_id FROM leagues WHERE league_id = $1", [league.league_id]);
    if (existingLeague.rowCount > 0) {
      await client.query("ROLLBACK");
      return { error: { status: 409, code: "LEAGUE_EXISTS", message: `League ${league.league_id} already exists.`, details: { league_id: league.league_id } } };
    }

    for (const fixture of league.fixtures) {
      const existingMatch = await client.query("SELECT match_id FROM matches WHERE match_id = $1", [fixture.match_id]);
      if (existingMatch.rowCount > 0) {
        await client.query("ROLLBACK");
        return { error: { status: 409, code: "MATCH_EXISTS", message: `Match ${fixture.match_id} already exists.`, details: { match_id: fixture.match_id } } };
      }
    }

    let lotsSeed = league.lots_seed;
    if (lotsSeed == null) {
      const meta = await client.query("SELECT lots_seed FROM meta WHERE id = 1");
      lotsSeed = meta.rowCount === 1 ? meta.rows[0].lots_seed : 42;
    }

    const sportConfig = sport.rows[0].config;
    const tieBreakOrder = league.tie_break_order || sportConfig.tie_break_order || TIE_BREAKS.slice();
    const config = {
      teams: league.teams,
      fixtures: league.fixtures,
      points: league.points,
      qualification: league.qualification,
      lots_seed: lotsSeed,
      tie_break_order: tieBreakOrder,
    };

    await client.query(
      `INSERT INTO leagues (league_id, tenant_id, name, sport_id, config)
       VALUES ($1, 'tenant-alpha', $1, $2, $3::jsonb)`,
      [league.league_id, league.sport_id, JSON.stringify(config)]
    );

    for (const fixture of league.fixtures) {
      await client.query(
        `INSERT INTO matches (match_id, league_id, sport_id, home_team_id, away_team_id, source)
         VALUES ($1, $2, $3, $4, $5, 'league_fixture')`,
        [fixture.match_id, league.league_id, league.sport_id, fixture.home, fixture.away]
      );
    }

    await client.query("COMMIT");
    return {
      ok: true,
      body: {
        league_id: league.league_id,
        status: "created",
        team_count: league.teams.length,
        fixture_count: league.fixtures.length,
      },
    };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { validateLeague, createLeague, validateId, isPlainObject, isInt };
