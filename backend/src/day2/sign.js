const { canonical, sign } = require('../canonical');

function day2Salt() {
  const salt = process.env.DAY2_SALT;
  if (typeof salt !== 'string' || salt.length === 0) {
    throw new TypeError('DAY2_SALT must be set in the environment');
  }
  return salt;
}

function signDay2(salt, entityId, sigPayload) {
  if (typeof salt !== 'string') {
    throw new TypeError('DAY2_SALT must be a string');
  }
  return sign(salt, entityId, sigPayload);
}

module.exports = { canonical, day2Salt, signDay2 };
