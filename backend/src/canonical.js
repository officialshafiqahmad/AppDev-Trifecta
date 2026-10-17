const crypto = require('crypto');

function canonical(value) {
  if (value === null || typeof value !== 'object') {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => canonical(item)).join(',')}]`;
  }
  const keys = Object.keys(value).sort();
  return `{${keys.map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`).join(',')}}`;
}

function sign(salt, id, payload) {
  if (typeof salt !== 'string') {
    throw new TypeError('DAY1_SALT must be a string');
  }
  const message = Buffer.from(`${id}|${canonical(payload)}`, 'utf8');
  return crypto.createHmac('sha256', Buffer.from(salt, 'utf8')).update(message).digest('hex');
}

function lotsKey(seed, leagueId, teamId) {
  return crypto.createHash("sha256").update(`${seed}|${leagueId}|${teamId}`, "utf8").digest("hex");
}

module.exports = { canonical, sign, lotsKey };
