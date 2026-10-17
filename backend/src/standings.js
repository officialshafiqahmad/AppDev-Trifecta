const { lotsKey } = require("./canonical");
const { projectMatch } = require("./scoring");
const { validateId } = require("./leagues");
const { TIE_BREAKS } = require("./sports");

function emptyPair() {
  return { played: 0, points: 0, scored: 0, conceded: 0 };
}

function oversFaced(side, sportConfig) {
  const periods = sportConfig.periods || {};
  const wicketsLimit = (periods.innings_per_team || 1) * (periods.wickets_per_innings || 0);
  if (wicketsLimit > 0 && Number(side.wickets) >= wicketsLimit) {
    return (periods.innings_per_team || 1) * (periods.overs_per_innings || 0);
  }
  const bpo = periods.balls_per_over || 6;
  return Number(side.balls || 0) / bpo;
}

function roundNrr(value) {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 1000) / 1000;
}

function rate(runs, overs) {
  if (!overs) return 0;
  return runs / overs;
}

function qualify(playedMatches, matchList, teams, winPoints, spots) {
  const remaining = {};
  for (const team of teams) remaining[team] = 0;
  for (const match of matchList) {
    const counted = playedMatches.some((item) => item.match.match_id === match.match_id);
    if (!counted) {
      remaining[match.home_team_id] += 1;
      remaining[match.away_team_id] += 1;
    }
  }
  return remaining;
}

function applyMatchToStats(stats, homeId, awayId, projection, points, sportConfig, filter = null) {
  if (filter && !filter.has(homeId) && !filter.has(awayId)) return;
  if (filter && (!filter.has(homeId) || !filter.has(awayId))) return;

  const homeScore = projection.home.score;
  const awayScore = projection.away.score;
  const home = stats[homeId];
  const away = stats[awayId];
  home.played += 1;
  away.played += 1;
  home.scored += homeScore;
  home.conceded += awayScore;
  away.scored += awayScore;
  away.conceded += homeScore;
  home.fair_play += projection.home.fair_play;
  away.fair_play += projection.away.fair_play;

  if (sportConfig.scoring_model === "innings") {
    const homeOvers = oversFaced(projection.home, sportConfig);
    const awayOvers = oversFaced(projection.away, sportConfig);
    home.runs += homeScore;
    home.oversFaced += homeOvers;
    home.runsAgainst += awayScore;
    home.oversBowled += awayOvers;
    away.runs += awayScore;
    away.oversFaced += awayOvers;
    away.runsAgainst += homeScore;
    away.oversBowled += homeOvers;
  }

  if (projection.outcome === "draw") {
    home.drawn += 1;
    away.drawn += 1;
    home.points += points.draw;
    away.points += points.draw;
  } else if (projection.winner_team_id === homeId) {
    home.won += 1;
    away.lost += 1;
    home.points += points.win;
    away.points += points.loss;
  } else if (projection.winner_team_id === awayId) {
    away.won += 1;
    home.lost += 1;
    away.points += points.win;
    home.points += points.loss;
  }
}

function finishDiff(row, sportConfig) {
  if (sportConfig.scoring_model === "innings") {
    row.diff = roundNrr(rate(row.runs, row.oversFaced) - rate(row.runsAgainst, row.oversBowled));
  } else {
    row.diff = row.scored - row.conceded;
  }
}

function buildStats(teams, played, points, sportConfig, group = null) {
  const filter = group ? new Set(group) : null;
  const stats = {};
  for (const team of teams) {
    stats[team] = {
      team_id: team,
      played: 0,
      won: 0,
      drawn: 0,
      lost: 0,
      scored: 0,
      conceded: 0,
      diff: 0,
      points: 0,
      fair_play: 0,
      runs: 0,
      oversFaced: 0,
      runsAgainst: 0,
      oversBowled: 0,
    };
  }
  for (const item of played) {
    applyMatchToStats(stats, item.match.home_team_id, item.match.away_team_id, item.projection, points, sportConfig, filter);
  }
  for (const team of teams) finishDiff(stats[team], sportConfig);
  return stats;
}

function buildH2h(teams, played, points) {
  const h2h = {};
  for (const a of teams) {
    h2h[a] = {};
    for (const b of teams) {
      if (a !== b) h2h[a][b] = emptyPair();
    }
  }
  for (const item of played) {
    const home = item.match.home_team_id;
    const away = item.match.away_team_id;
    if (!h2h[home] || !h2h[home][away]) continue;
    const homePoints = item.projection.outcome === "draw"
      ? points.draw
      : item.projection.winner_team_id === home
        ? points.win
        : points.loss;
    const awayPoints = item.projection.outcome === "draw"
      ? points.draw
      : item.projection.winner_team_id === away
        ? points.win
        : points.loss;
    h2h[home][away].played += 1;
    h2h[away][home].played += 1;
    h2h[home][away].points += homePoints;
    h2h[away][home].points += awayPoints;
    h2h[home][away].scored += item.projection.home.score;
    h2h[home][away].conceded += item.projection.away.score;
    h2h[away][home].scored += item.projection.away.score;
    h2h[away][home].conceded += item.projection.home.score;
  }
  return h2h;
}

function criterionValue(criterion, teamId, groupStats, overall, lotsSeed, leagueId) {
  if (criterion === "h2h_points") return groupStats[teamId].points;
  if (criterion === "h2h_diff") return groupStats[teamId].diff;
  if (criterion === "overall_diff") return overall[teamId].diff;
  if (criterion === "scored") return overall[teamId].scored;
  if (criterion === "fair_play") return overall[teamId].fair_play;
  if (criterion === "draw_lots") return lotsKey(lotsSeed, leagueId, teamId);
  return 0;
}

function valuesEqual(a, b, criterion) {
  if (criterion === "draw_lots") return a === b;
  return a === b;
}

function compareValues(a, b, criterion) {
  if (criterion === "draw_lots") return a < b ? -1 : a > b ? 1 : 0;
  if (a > b) return -1;
  if (a < b) return 1;
  return 0;
}

function resolveGroup(group, overall, played, points, sportConfig, order, lotsSeed, leagueId) {
  if (group.length <= 1) {
    return group.map((team) => ({ team_id: team, resolved_by: null }));
  }

  const groupStats = buildStats(group, played, points, sportConfig, group);
  for (const criterion of order) {
    const valued = group.map((team) => ({
      team,
      value: criterionValue(criterion, team, groupStats, overall, lotsSeed, leagueId),
    }));
    const first = valued[0].value;
    if (valued.every((item) => valuesEqual(item.value, first, criterion))) continue;

    const sortedUnique = [...new Set(valued.map((item) => item.value))].sort((a, b) => compareValues(a, b, criterion));
    const subgroups = sortedUnique.map((value) => valued.filter((item) => valuesEqual(item.value, value, criterion)).map((item) => item.team));
    const out = [];
    subgroups.forEach((subgroup, index) => {
      const part = subgroup.length > 1
        ? resolveGroup(subgroup, overall, played, points, sportConfig, order, lotsSeed, leagueId)
        : [{ team_id: subgroup[0], resolved_by: null }];
      if (index < subgroups.length - 1) {
        part[part.length - 1].resolved_by = criterion;
      }
      out.push(...part);
    });
    return out;
  }
  return group.map((team) => ({ team_id: team, resolved_by: null }));
}

function qualificationStatus(teamId, teams, stats, remaining, winPoints, spots) {
  const pointsT = stats[teamId].points;
  const maxT = pointsT + winPoints * remaining[teamId];
  const others = teams.filter((team) => team !== teamId);
  const clinched = others.filter((team) => stats[team].points + winPoints * remaining[team] >= pointsT).length < spots;
  if (clinched) return "clinched";
  const eliminated = others.filter((team) => stats[team].points > maxT).length >= spots;
  if (eliminated) return "eliminated";
  return "still_possible";
}

async function getStandings(pool, leagueId) {
  if (!validateId(leagueId)) {
    return { error: { status: 400, code: "VALIDATION_ERROR", message: "Invalid league_id.", details: { fields: ["league_id"] } } };
  }

  const leagueRes = await pool.query("SELECT league_id, sport_id, config FROM leagues WHERE league_id = $1", [leagueId]);
  if (leagueRes.rowCount === 0) {
    return { error: { status: 404, code: "LEAGUE_NOT_FOUND", message: `League ${leagueId} was not found.`, details: { league_id: leagueId } } };
  }

  const league = leagueRes.rows[0];
  const config = league.config || {};
  const teams = Array.isArray(config.teams) ? config.teams.slice() : [];
  const points = config.points || { win: 3, draw: 1, loss: 0 };
  const spots = config.qualification && Number.isInteger(config.qualification.spots) ? config.qualification.spots : 1;
  const lotsSeed = config.lots_seed == null ? 42 : config.lots_seed;
  const order = Array.isArray(config.tie_break_order) && config.tie_break_order.length
    ? config.tie_break_order
    : TIE_BREAKS.slice();
  if (!order.includes("draw_lots")) order.push("draw_lots");

  const sportRes = await pool.query("SELECT config FROM sports WHERE sport_id = $1", [league.sport_id]);
  const sportConfig = sportRes.rowCount ? sportRes.rows[0].config : { scoring_model: "event", scoring_events: {} };

  const matchesRes = await pool.query(
    "SELECT * FROM matches WHERE league_id = $1 ORDER BY match_id",
    [leagueId]
  );
  const eventsRes = await pool.query(
    `SELECT match_events.*
     FROM match_events
     JOIN matches ON matches.match_id = match_events.match_id
     WHERE matches.league_id = $1
     ORDER BY match_events.match_id, match_events.sequence`,
    [leagueId]
  );
  const eventsByMatch = new Map();
  for (const row of eventsRes.rows) {
    if (!eventsByMatch.has(row.match_id)) eventsByMatch.set(row.match_id, []);
    eventsByMatch.get(row.match_id).push(row);
  }

  const projected = matchesRes.rows.map((match) => ({
    match,
    projection: projectMatch(match, sportConfig, eventsByMatch.get(match.match_id) || []),
  }));
  const played = projected.filter((item) => item.projection.status === "completed" && item.projection.outcome !== "undecided");
  const remaining = qualify(played, matchesRes.rows, teams, points.win, spots);
  const overall = buildStats(teams, played, points, sportConfig);
  const h2h = buildH2h(teams, played, points);

  const byPoints = new Map();
  for (const team of teams) {
    const pts = overall[team].points;
    if (!byPoints.has(pts)) byPoints.set(pts, []);
    byPoints.get(pts).push(team);
  }
  const pointValues = [...byPoints.keys()].sort((a, b) => b - a);
  const ranked = [];
  for (const pts of pointValues) {
    ranked.push(...resolveGroup(byPoints.get(pts), overall, played, points, sportConfig, order, lotsSeed, leagueId));
  }

  const table = ranked.map((entry, index) => {
    const row = overall[entry.team_id];
    const next = ranked[index + 1];
    return {
      rank: index + 1,
      team_id: entry.team_id,
      played: row.played,
      won: row.won,
      drawn: row.drawn,
      lost: row.lost,
      scored: row.scored,
      conceded: row.conceded,
      diff: row.diff,
      points: row.points,
      fair_play: row.fair_play,
      status: qualificationStatus(entry.team_id, teams, overall, remaining, points.win, spots),
      resolved_by: next && overall[next.team_id].points === row.points ? entry.resolved_by : null,
    };
  });

  return {
    status: 200,
    body: {
      league_id: league.league_id,
      sport_id: league.sport_id,
      qualification_spots: spots,
      table,
      h2h,
    },
  };
}

module.exports = { getStandings, oversFaced, roundNrr };
