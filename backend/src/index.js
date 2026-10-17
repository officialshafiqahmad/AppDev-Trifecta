const { createClient } = require('redis');
const { createApp } = require('./app');
const { createPool, waitForDb, migrate, ensureBaseline } = require('./db');

async function connectRedis() {
  const client = createClient({ url: process.env.REDIS_URL });
  client.on('error', (error) => {
    console.error(`redis error: ${error.message}`);
  });
  let lastError;
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    try {
      if (!client.isOpen) await client.connect();
      const pong = await client.ping();
      if (pong !== 'PONG') throw new Error('redis ping failed');
      return client;
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  throw lastError;
}

async function main() {
  if (typeof process.env.DAY1_SALT !== 'string') {
    throw new Error('DAY1_SALT must be set in the environment');
  }
  const pool = createPool();
  await waitForDb(pool);
  await migrate(pool);
  await ensureBaseline(pool);
  const redis = await connectRedis();
  const app = createApp(pool);
  app.locals.redis = redis;
  const port = Number(process.env.PORT || 8080);
  app.listen(port, '0.0.0.0', () => {
    console.log(`api listening on ${port}`);
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
