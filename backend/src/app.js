const express = require('express');
const { sendError } = require('./errors');
const { validateSport } = require('./sports');
const { validateReset, applyReset } = require('./baseline');
const { databaseReady } = require('./db');
const { validateLeague, createLeague } = require('./leagues');
const { appendEvent, getScore } = require('./scoring');
const { getStandings } = require('./standings');
const { checkout, getInventory } = require('./store');
const { mountRbac } = require('./rbac');
const { rateLimitApi } = require('./ratelimit');
const { handleStreamKey } = require('./day2/stream-key');
const { handleCostream } = require('./day2/costream');
const { exportQr, resolveQr, resolveShortCode } = require('./day2/qr');

const MAX_BODY = 1024 * 1024;

function createApp(pool) {
  const app = express();

  app.use((req, res, next) => {
    const length = Number(req.headers['content-length'] || 0);
    if (Number.isFinite(length) && length > MAX_BODY) {
      sendError(res, 413, 'PAYLOAD_TOO_LARGE', 'Request body exceeds 1 MB.', {});
      return;
    }
    next();
  });

  app.use(express.json({ limit: MAX_BODY }));
  mountRbac(app, pool);

  app.get('/api/v1/ping', rateLimitApi(), (req, res) => {
    res.status(200).json({ pong: true });
  });

  app.get('/health', async (req, res, next) => {
    try {
      const ready = await databaseReady(pool);
      if (!ready) {
        res.status(503).json({ status: 'unavailable' });
        return;
      }
      res.status(200).json({ status: 'ok' });
    } catch (error) {
      res.status(503).json({ status: 'unavailable' });
    }
  });

  app.post('/audit/v1/reset', async (req, res, next) => {
    try {
      const parsed = validateReset(req.body);
      if (!parsed.ok) {
        sendError(res, 400, 'VALIDATION_ERROR', 'Request validation failed.', { fields: parsed.fields });
        return;
      }
      await applyReset(pool, parsed);
      res.status(200).json({
        status: 'reset_complete',
        seed: parsed.seed,
        sports: ['football', 'basketball', 'cricket', 'esports'],
        tenants: ['tenant-alpha', 'tenant-beta'],
        stock: parsed.stock,
      });
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/sports', async (req, res, next) => {
    try {
      const parsed = validateSport(req.body);
      if (!parsed.ok) {
        sendError(res, 400, 'VALIDATION_ERROR', 'Request validation failed.', { fields: parsed.fields });
        return;
      }
      const { config } = parsed;
      try {
        await pool.query(
          `INSERT INTO sports (sport_id, name, scoring_model, config)
           VALUES ($1, $2, $3, $4::jsonb)`,
          [config.sport_id, config.name, config.scoring_model, JSON.stringify(config)],
        );
      } catch (error) {
        if (error.code === '23505') {
          sendError(res, 409, 'SPORT_EXISTS', `Sport ${config.sport_id} already exists.`, {
            sport_id: config.sport_id,
          });
          return;
        }
        throw error;
      }
      res.status(201).json({
        sport_id: config.sport_id,
        status: 'created',
        config,
      });
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/leagues', async (req, res, next) => {
    try {
      const parsed = validateLeague(req.body);
      if (!parsed.ok) {
        sendError(res, 400, 'VALIDATION_ERROR', 'Request validation failed.', { fields: parsed.fields });
        return;
      }
      const result = await createLeague(pool, parsed.league);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(201).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/events', async (req, res, next) => {
    try {
      const result = await appendEvent(pool, req.body);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(result.status).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/checkout', async (req, res, next) => {
    try {
      const result = await checkout(pool, req.body, req.app.locals.redis);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(result.status).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/audit/v1/inventory/:variant_id', async (req, res, next) => {
    try {
      const result = await getInventory(pool, req.params.variant_id);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(200).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/audit/v1/standings/:league_id', async (req, res, next) => {
    try {
      const result = await getStandings(pool, req.params.league_id);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(200).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/audit/v1/score/:match_id', async (req, res, next) => {
    try {
      const result = await getScore(pool, req.params.match_id);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(200).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/stream/key', async (req, res, next) => {
    try {
      const result = await handleStreamKey(pool, req.body);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(result.status).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.post('/audit/v1/costream/session', async (req, res, next) => {
    try {
      const result = await handleCostream(pool, req.body);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(result.status).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/audit/v1/qr/:entity_id/export.:format', async (req, res, next) => {
    try {
      const result = await exportQr(pool, req.params.entity_id, req.params.format);
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(200).set('Content-Type', result.contentType).send(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/audit/v1/qr/:entity_id', async (req, res, next) => {
    try {
      const result = await resolveQr(pool, req.params.entity_id, {
        inspect: req.query.inspect === 'true',
        userAgent: req.get('user-agent'),
      });
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(200).json(result.body);
    } catch (error) {
      next(error);
    }
  });

  app.get('/q/:short_code', async (req, res, next) => {
    try {
      const result = await resolveShortCode(pool, req.params.short_code, req.get('user-agent'));
      if (result.error) {
        sendError(res, result.error.status, result.error.code, result.error.message, result.error.details);
        return;
      }
      res.status(302).set('Location', result.location).end();
    } catch (error) {
      next(error);
    }
  });

  app.use((error, req, res, next) => {
    if (res.headersSent) {
      next(error);
      return;
    }
    if (error.type === 'entity.too.large' || error.status === 413) {
      sendError(res, 413, 'PAYLOAD_TOO_LARGE', 'Request body exceeds 1 MB.', {});
      return;
    }
    if (error instanceof SyntaxError && error.status === 400 && Object.prototype.hasOwnProperty.call(error, 'body')) {
      sendError(res, 400, 'VALIDATION_ERROR', 'Malformed JSON.', { fields: [] });
      return;
    }
    console.error(error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Unexpected server error.',
        details: {},
      },
    });
  });

  return app;
}

module.exports = { createApp };
