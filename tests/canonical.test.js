const test = require('node:test');
const assert = require('node:assert/strict');
const { canonical, sign } = require('../backend/src/canonical');

test('canonical JSON matches Appendix A vector', () => {
  const payload = { team_id: 't1', event_type: 'goal' };
  assert.equal(canonical(payload), '{"event_type":"goal","team_id":"t1"}');
});

test('HMAC-SHA256 matches Appendix A test vector 1', () => {
  const signature = sign('demo-salt', 'evt-1', { team_id: 't1', event_type: 'goal' });
  assert.equal(signature, '972a8b558690b19121cc5bea84978f85e8eb15a3735018db36616bab1d7ec501');
});

test('canonical JSON keeps array order and does not escape non-ASCII', () => {
  assert.equal(canonical({ b: 1, a: ['é', true, null] }), '{"a":["é",true,null],"b":1}');
});

test('sign does not trim the salt', () => {
  const raw = sign(' demo-salt ', 'evt-1', { team_id: 't1', event_type: 'goal' });
  const trimmed = sign('demo-salt', 'evt-1', { team_id: 't1', event_type: 'goal' });
  assert.notEqual(raw, trimmed);
});
