const crypto = require("crypto");

function jwtSecret() {
  const secret = process.env.JWT_SECRET || process.env.DAY1_SALT;
  if (typeof secret !== "string" || secret.length === 0) {
    throw new Error("JWT_SECRET is required");
  }
  return secret;
}

function signJwt(claims, options = {}) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    ...claims,
    iat: options.iat || now,
    exp: options.exp || now + (options.ttlSec || 3600),
  };
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = crypto.createHmac("sha256", jwtSecret()).update(`${header}.${body}`).digest("base64url");
  return `${header}.${body}.${signature}`;
}

function verifyJwt(token) {
  if (typeof token !== "string" || token.split(".").length !== 3) {
    const error = new Error("malformed");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  const [headerPart, payloadPart, signaturePart] = token.split(".");
  let header;
  try {
    header = JSON.parse(Buffer.from(headerPart, "base64url").toString("utf8"));
  } catch (_err) {
    const error = new Error("malformed");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  if (!header || header.alg !== "HS256") {
    const error = new Error("algorithm");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  const expected = crypto.createHmac("sha256", jwtSecret()).update(`${headerPart}.${payloadPart}`).digest("base64url");
  const left = Buffer.from(expected);
  const right = Buffer.from(signaturePart);
  if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) {
    const error = new Error("signature");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  let payload;
  try {
    payload = JSON.parse(Buffer.from(payloadPart, "base64url").toString("utf8"));
  } catch (_err) {
    const error = new Error("malformed");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  if (!payload || typeof payload.exp !== "number" || payload.exp <= Math.floor(Date.now() / 1000)) {
    const error = new Error("expired");
    error.code = "UNAUTHENTICATED";
    throw error;
  }
  return payload;
}

function bearerToken(req) {
  const header = req.headers.authorization;
  if (typeof header !== "string") return null;
  const match = header.match(/^Bearer\s+(\S+)$/);
  return match ? match[1] : null;
}

module.exports = { jwtSecret, signJwt, verifyJwt, bearerToken };
