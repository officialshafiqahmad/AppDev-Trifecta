const { createClient } = require("redis");

const QUEUE_KEY = "trifecta:order-events";

async function connectRedis(url) {
  const client = createClient({ url });
  client.on("error", (error) => {
    console.error(`worker redis error: ${error.message}`);
  });
  await client.connect();
  return client;
}

async function storeObject(orderId, payload) {
  const base = process.env.OBJECT_STORE_URL;
  if (!base) return;
  await fetch(`${base}/objects/${encodeURIComponent(orderId)}`, {
    method: "PUT",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(payload),
  });
}

async function main() {
  const url = process.env.QUEUE_URL || process.env.REDIS_URL;
  if (!url) {
    throw new Error("QUEUE_URL or REDIS_URL must be set");
  }
  const redis = await connectRedis(url);
  console.log("worker consuming order events");

  const tick = async () => {
    try {
      const item = await redis.rPop(QUEUE_KEY);
      if (!item) return;
      const payload = JSON.parse(item);
      await storeObject(payload.order_id || `event-${Date.now()}`, payload);
    } catch (error) {
      console.error(`worker tick failed: ${error.message}`);
    }
  };

  setInterval(() => {
    tick().catch((error) => console.error(error.message));
  }, 500);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
