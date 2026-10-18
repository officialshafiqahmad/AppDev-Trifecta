const GUEST_WRITE_PATHS = new Set([
  '/api/v1/chat',
  '/audit/v1/checkout',
  '/audit/v1/events',
]);

function bearerToken(req) {
  const header = req.headers.authorization || req.headers.Authorization || '';
  const match = /^Bearer\s+(\S+)\s*$/i.exec(header);
  return match ? match[1] : null;
}

function guestWriteDecision(token) {
  if (typeof token === 'string' && token.startsWith('guest_')) {
    return {
      blocked: true,
      status: 403,
      code: 'GUEST_WRITE_FORBIDDEN',
      token,
    };
  }
  return { blocked: false, status: null, code: null, token: token || null };
}

function guestWriteBlock(req) {
  if (req.method !== 'POST' && req.method !== 'PUT' && req.method !== 'PATCH' && req.method !== 'DELETE') {
    return null;
  }
  const token = bearerToken(req);
  const decision = guestWriteDecision(token);
  if (!decision.blocked) return null;
  const path = req.path;
  const rosterWrite = path.startsWith('/audit/v1/rbac/') && req.method !== 'GET';
  const apiWrite = path.startsWith('/api/v1/') && path !== '/api/v1/ping';
  if (!GUEST_WRITE_PATHS.has(path) && !rosterWrite && !apiWrite) return null;
  return decision;
}

module.exports = {
  GUEST_WRITE_PATHS,
  bearerToken,
  guestWriteBlock,
  guestWriteDecision,
};
