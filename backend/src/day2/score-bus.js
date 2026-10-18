const { EventEmitter } = require('events');

const bus = new EventEmitter();
bus.setMaxListeners(0);

function publishScore(matchId, body) {
  bus.emit(matchId, body);
}

function subscribeScore(matchId, listener) {
  bus.on(matchId, listener);
  return () => bus.off(matchId, listener);
}

module.exports = { publishScore, subscribeScore };
