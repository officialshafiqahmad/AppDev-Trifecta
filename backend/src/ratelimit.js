function clientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  return req.socket.remoteAddress || "unknown";
}

function rateLimitApi(windowMs = 10000, max = 100) {
  return async (req, res, next) => {
    if (!req.path.startsWith("/api/v1/")) {
      next();
      return;
    }
    const redis = req.app.locals.redis;
    if (!redis) {
      next();
      return;
    }
    const now = Date.now();
    const key = `ratelimit:${clientIp(req)}`;
    try {
      await redis.zRemRangeByScore(key, 0, now - windowMs);
      const count = await redis.zCard(key);
      if (count >= max) {
        const oldest = await redis.zRangeWithScores(key, 0, 0);
        const retryAfter = oldest.length > 0
          ? Math.max(1, Math.ceil((oldest[0].score + windowMs - now) / 1000))
          : Math.ceil(windowMs / 1000);
        res.set("Retry-After", String(retryAfter));
        res.status(429).json({
          error: {
            code: "RATE_LIMITED",
            message: "Too many requests.",
            details: { retry_after: retryAfter },
          },
        });
        return;
      }
      await redis.zAdd(key, { score: now, value: `${now}:${count}:${Math.random()}` });
      await redis.expire(key, Math.ceil(windowMs / 1000) + 5);
      next();
    } catch (error) {
      next(error);
    }
  };
}

module.exports = { rateLimitApi, clientIp };
