const crypto = require("crypto");
const { sign } = require("./canonical");
const { validateId, isPlainObject, isInt } = require("./leagues");

const EVENT_TYPES = new Set([
  "match_init",
  "match_start",
  "score",
  "discipline",
  "tiebreak_winner",
  "match_end",
  "compensation",
]);

function requestHash(body) {
  return crypto
    .createHash("sha256")
    .update(
      JSON.stringify({
        event_id: body.event_id,
        match_id: body.match_id,
        type: body.type,
        payload: body.payload,
      })
    )
    .digest("hex");
}

function validateEventBody(body) {
  if (!isPlainObject(body)) return { ok: false, fields: ["body"] };
  const fields = [];
  if (!validateId(body.event_id)) fields.push("event_id");
  if (!validateId(body.match_id)) fields.push("match_id");
  if (typeof body.type !== "string" || !EVENT_TYPES.has(body.type)) fields.push("type");
  if (!isPlainObject(body.payload)) fields.push("payload");
  if (fields.length > 0) return { ok: false, fields };

  const payload = body.payload;
  if (body.type === "match_init") {
    if (!validateId(payload.sport_id)) fields.push("payload.sport_id");
    if (!validateId(payload.home_team_id)) fields.push("payload.home_team_id");
    if (!validateId(payload.away_team_id)) fields.push("payload.away_team_id");
    if (payload.home_team_id === payload.away_team_id) fields.push("payload.away_team_id");
    if (Object.prototype.hasOwnProperty.call(payload, "league_id") && !validateId(payload.league_id)) {
      fields.push("payload.league_id");
    }
  } else if (body.type === "score") {
    if (!validateId(payload.team_id)) fields.push("payload.team_id");
    if (typeof payload.event_type !== "string" || payload.event_type.length < 1) fields.push("payload.event_type");
  } else if (body.type === "discipline") {
    if (!validateId(payload.team_id)) fields.push("payload.team_id");
    if (!isInt(payload.points)) fields.push("payload.points");
  } else if (body.type === "tiebreak_winner") {
    if (!validateId(payload.team_id)) fields.push("payload.team_id");
  } else if (body.type === "compensation") {
    if (!validateId(payload.compensates)) fields.push("payload.compensates");
    if (typeof payload.reason !== "string") fields.push("payload.reason");
  } else if (body.type === "match_start" || body.type === "match_end") {
    // empty payload is valid; extra keys ignored
  }

  if (fields.length > 0) return { ok: false, fields };
  return { ok: true };
}

function normalizedPayload(type, payload) {
  if (type === "match_init") {
    const out = {
      sport_id: payload.sport_id,
      home_team_id: payload.home_team_id,
      away_team_id: payload.away_team_id,
    };
    if (payload.league_id) out.league_id = payload.league_id;
    return out;
  }
  if (type === "score") return { team_id: payload.team_id, event_type: payload.event_type };
  if (type === "discipline") return { team_id: payload.team_id, points: payload.points };
  if (type === "tiebreak_winner") return { team_id: payload.team_id };
  if (type === "compensation") return { compensates: payload.compensates, reason: payload.reason };
  return {};
}

function sideOf(match, teamId) {
  if (teamId === match.home_team_id) return "home";
  if (teamId === match.away_team_id) return "away";
  return null;
}

function projectMatch(match, sportConfig, rows) {
  const compensatedBy = {};
  for (const row of rows) {
    if (row.type === "compensation") {
      compensatedBy[row.payload.compensates] = row.event_id;
    }
  }

  let started = false;
  let ended = false;
  const home = {
    team_id: match.home_team_id,
    score: 0,
    wickets: sportConfig.scoring_model === "innings" ? 0 : null,
    balls: sportConfig.scoring_model === "innings" ? 0 : null,
    overs: sportConfig.scoring_model === "innings" ? "0.0" : null,
    fair_play: 0,
  };
  const away = {
    team_id: match.away_team_id,
    score: 0,
    wickets: sportConfig.scoring_model === "innings" ? 0 : null,
    balls: sportConfig.scoring_model === "innings" ? 0 : null,
    overs: sportConfig.scoring_model === "innings" ? "0.0" : null,
    fair_play: 0,
  };
  const sides = { home, away };
  let tiebreakTeam = null;

  for (const row of rows) {
    if (row.type === "match_start") started = true;
    if (row.type === "match_end") ended = true;
    if (compensatedBy[row.event_id] || row.type === "compensation") continue;
    if (row.type === "score") {
      const side = sides[sideOf(match, row.payload.team_id)];
      const def = sportConfig.scoring_events[row.payload.event_type];
      if (!side || !def) continue;
      if (sportConfig.scoring_model === "event") side.score += def.points;
      else if (sportConfig.scoring_model === "innings") {
        side.score += def.runs;
        if (def.legal_ball) side.balls += 1;
        if (def.wicket) side.wickets += 1;
      } else if (sportConfig.scoring_model === "round") {
        side.score += def.rounds;
      }
    } else if (row.type === "discipline") {
      const side = sides[sideOf(match, row.payload.team_id)];
      if (side) side.fair_play += row.payload.points;
    } else if (row.type === "tiebreak_winner") {
      tiebreakTeam = row.payload.team_id;
    }
  }

  if (sportConfig.scoring_model === "innings") {
    const bpo = sportConfig.periods.balls_per_over;
    for (const side of [home, away]) {
      side.overs = `${Math.floor(side.balls / bpo)}.${side.balls % bpo}`;
    }
  }

  let status = "upcoming";
  if (ended) status = "completed";
  else if (started) status = "in_progress";

  let winner = null;
  if (home.score > away.score) winner = home.team_id;
  else if (away.score > home.score) winner = away.team_id;
  else if (tiebreakTeam) winner = tiebreakTeam;

  let outcome = "pending";
  if (status === "completed") {
    if (home.score > away.score) outcome = "home_win";
    else if (away.score > home.score) outcome = "away_win";
    else if (tiebreakTeam === home.team_id) outcome = "home_win";
    else if (tiebreakTeam === away.team_id) outcome = "away_win";
    else if (sportConfig.draw_allowed) outcome = "draw";
    else outcome = "undecided";
  }

  return {
    status,
    outcome,
    winner_team_id: status === "completed" ? winner : home.score === away.score && !tiebreakTeam ? null : winner && status === "completed" ? winner : status === "completed" ? winner : null,
    tiebreak_winner_team_id: tiebreakTeam,
    home,
    away,
    events: rows.map((row) => ({
      sequence: row.sequence,
      event_id: row.event_id,
      type: row.type,
      payload: row.payload,
      signature: row.signature,
      compensated: Boolean(compensatedBy[row.event_id]),
      compensated_by: compensatedBy[row.event_id] || null,
    })),
  };
}

function inningsLimitReached(side, sportConfig) {
  const { innings_per_team, overs_per_innings, balls_per_over, wickets_per_innings } = sportConfig.periods;
  const maxBalls = innings_per_team * overs_per_innings * balls_per_over;
  const maxWickets = innings_per_team * wickets_per_innings;
  return side.balls >= maxBalls || side.wickets >= maxWickets;
}

function seriesDecided(side, sportConfig) {
  return side.score >= Math.floor((sportConfig.periods.best_of + 1) / 2);
}

async function loadMatchBundle(client, matchId) {
  const matchRes = await client.query("SELECT * FROM matches WHERE match_id = $1", [matchId]);
  if (matchRes.rowCount === 0) return null;
  const match = matchRes.rows[0];
  const sportRes = await client.query("SELECT config FROM sports WHERE sport_id = $1", [match.sport_id]);
  const eventsRes = await client.query(
    "SELECT * FROM match_events WHERE match_id = $1 ORDER BY sequence ASC",
    [matchId]
  );
  return {
    match,
    sportConfig: sportRes.rows[0].config,
    events: eventsRes.rows,
  };
}

async function appendEvent(pool, body) {
  const parsed = validateEventBody(body);
  if (!parsed.ok) {
    return { error: { status: 400, code: "VALIDATION_ERROR", message: "Request validation failed.", details: { fields: parsed.fields } } };
  }

  const salt = process.env.DAY1_SALT;
  const payload = normalizedPayload(body.type, body.payload);
  const hash = requestHash({ event_id: body.event_id, match_id: body.match_id, type: body.type, payload });
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    await client.query("SELECT pg_advisory_xact_lock(hashtext($1))", [body.match_id]);

    const existingEvent = await client.query("SELECT request_hash, response FROM match_events WHERE event_id = $1", [body.event_id]);
    if (existingEvent.rowCount === 1) {
      if (existingEvent.rows[0].request_hash === hash) {
        await client.query("COMMIT");
        return { status: 200, body: existingEvent.rows[0].response };
      }
      await client.query("ROLLBACK");
      return { error: { status: 409, code: "DUPLICATE_EVENT_ID", message: `Event ${body.event_id} already exists with a different body.`, details: { event_id: body.event_id } } };
    }

    if (body.type === "match_init") {
      const sport = await client.query("SELECT sport_id FROM sports WHERE sport_id = $1", [payload.sport_id]);
      if (sport.rowCount === 0) {
        await client.query("ROLLBACK");
        return { error: { status: 404, code: "SPORT_NOT_FOUND", message: `Sport ${payload.sport_id} was not found.`, details: { sport_id: payload.sport_id } } };
      }
      const existingMatch = await client.query("SELECT match_id FROM matches WHERE match_id = $1", [body.match_id]);
      if (existingMatch.rowCount > 0) {
        await client.query("ROLLBACK");
        return { error: { status: 409, code: "MATCH_EXISTS", message: `Match ${body.match_id} already exists.`, details: { match_id: body.match_id } } };
      }
      await client.query(
        `INSERT INTO matches (match_id, league_id, sport_id, home_team_id, away_team_id, source)
         VALUES ($1, $2, $3, $4, $5, 'match_init')`,
        [body.match_id, payload.league_id || null, payload.sport_id, payload.home_team_id, payload.away_team_id]
      );
    }

    const bundle = await loadMatchBundle(client, body.match_id);
    if (!bundle) {
      await client.query("ROLLBACK");
      return { error: { status: 404, code: "MATCH_NOT_FOUND", message: `Match ${body.match_id} was not found.`, details: { match_id: body.match_id } } };
    }

    const projection = projectMatch(bundle.match, bundle.sportConfig, bundle.events);
    const { match, sportConfig } = bundle;

    if (body.type !== "match_init") {
      if (body.type === "match_start") {
        if (projection.status !== "upcoming") {
          await client.query("ROLLBACK");
          return { error: { status: 409, code: "ILLEGAL_TRANSITION", message: "Match cannot be started from the current status.", details: { match_id: body.match_id, status: projection.status } } };
        }
      } else if (body.type === "match_end") {
        if (projection.status !== "in_progress") {
          await client.query("ROLLBACK");
          return { error: { status: 409, code: "ILLEGAL_TRANSITION", message: "Match cannot be ended from the current status.", details: { match_id: body.match_id, status: projection.status } } };
        }
        if (projection.home.score === projection.away.score && !sportConfig.draw_allowed && !projection.tiebreak_winner_team_id) {
          await client.query("ROLLBACK");
          return { error: { status: 409, code: "TIE_NOT_ALLOWED", message: "Level scores cannot end this match without a tie-break winner.", details: { match_id: body.match_id } } };
        }
      } else if (body.type === "score" || body.type === "discipline" || body.type === "tiebreak_winner") {
        if (projection.status !== "in_progress") {
          await client.query("ROLLBACK");
          return { error: { status: 409, code: "MATCH_NOT_IN_PROGRESS", message: "Score-changing events require an in-progress match.", details: { match_id: body.match_id, status: projection.status } } };
        }
        if (!sideOf(match, payload.team_id)) {
          await client.query("ROLLBACK");
          return { error: { status: 400, code: "VALIDATION_ERROR", message: "team_id must be the home or away team.", details: { fields: ["payload.team_id"] } } };
        }
        if (body.type === "score") {
          if (!Object.prototype.hasOwnProperty.call(sportConfig.scoring_events, payload.event_type)) {
            await client.query("ROLLBACK");
            return { error: { status: 400, code: "UNKNOWN_EVENT_TYPE", message: `Event type ${payload.event_type} is not defined for this sport.`, details: { event_type: payload.event_type } } };
          }
          const sideName = sideOf(match, payload.team_id);
          const side = projection[sideName];
          if (sportConfig.scoring_model === "innings" && inningsLimitReached(side, sportConfig)) {
            await client.query("ROLLBACK");
            return { error: { status: 409, code: "INNINGS_COMPLETE", message: "No further score events are allowed for this team.", details: { team_id: payload.team_id } } };
          }
          if (sportConfig.scoring_model === "round" && seriesDecided(side, sportConfig)) {
            await client.query("ROLLBACK");
            return { error: { status: 409, code: "SERIES_ALREADY_DECIDED", message: "The series is already decided.", details: { team_id: payload.team_id } } };
          }
        }
      } else if (body.type === "compensation") {
        const target = bundle.events.find((row) => row.event_id === payload.compensates);
        if (!target) {
          await client.query("ROLLBACK");
          return { error: { status: 404, code: "EVENT_NOT_FOUND", message: `Event ${payload.compensates} was not found.`, details: { event_id: payload.compensates } } };
        }
        const already = bundle.events.some((row) => row.type === "compensation" && row.payload.compensates === payload.compensates);
        const allowed = new Set(["score", "discipline", "tiebreak_winner"]);
        if (already || !allowed.has(target.type) || target.match_id !== body.match_id) {
          await client.query("ROLLBACK");
          return { error: { status: 409, code: "INVALID_COMPENSATION", message: "The target event cannot be compensated.", details: { event_id: payload.compensates } } };
        }
      }
    }

    const sequence = bundle.events.length + 1;
    const signature = sign(salt, body.event_id, payload);
    const response = {
      event_id: body.event_id,
      match_id: body.match_id,
      type: body.type,
      sequence,
      match_version: sequence,
      signature,
    };

    await client.query(
      `INSERT INTO match_events (event_id, match_id, type, payload, sequence, signature, request_hash, response)
       VALUES ($1, $2, $3, $4::jsonb, $5, $6, $7, $8::jsonb)`,
      [body.event_id, body.match_id, body.type, JSON.stringify(payload), sequence, signature, hash, JSON.stringify(response)]
    );
    await client.query("COMMIT");
    return { status: 201, body: response };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function getScore(pool, matchId) {
  if (!validateId(matchId)) {
    return { error: { status: 400, code: "VALIDATION_ERROR", message: "Invalid match_id.", details: { fields: ["match_id"] } } };
  }
  const client = await pool.connect();
  try {
    const bundle = await loadMatchBundle(client, matchId);
    if (!bundle) {
      return { error: { status: 404, code: "MATCH_NOT_FOUND", message: `Match ${matchId} was not found.`, details: { match_id: matchId } } };
    }
    const projection = projectMatch(bundle.match, bundle.sportConfig, bundle.events);
    return {
      status: 200,
      body: {
        match_id: bundle.match.match_id,
        sport_id: bundle.match.sport_id,
        league_id: bundle.match.league_id,
        status: projection.status,
        outcome: projection.outcome,
        winner_team_id: projection.status === "completed" ? projection.winner_team_id : null,
        tiebreak_winner_team_id: projection.tiebreak_winner_team_id,
        home: projection.home,
        away: projection.away,
        version: bundle.events.length,
        events: projection.events,
      },
    };
  } finally {
    client.release();
  }
}

module.exports = { appendEvent, getScore, projectMatch, validateEventBody };
