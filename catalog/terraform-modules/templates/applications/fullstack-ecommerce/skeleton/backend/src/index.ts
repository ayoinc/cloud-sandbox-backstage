import type { AddressInfo } from 'node:net';
import { Redis } from 'ioredis';
import { createApp } from './app.js';
import { noCache, RedisCache } from './cache.js';
import { loadConfig } from './config.js';
import { createDb, migrate, seedSampleData } from './db.js';
import { SandboxPaymentProvider } from './payments.js';

const config = loadConfig();
const db = createDb(config.databaseUrl);
await migrate(db);
if (config.seedSampleData) await seedSampleData(db);

const redis = config.features.caching && config.redisUrl ? new Redis(config.redisUrl) : undefined;
if (config.features.caching && !redis) {
  console.warn('Caching is on but REDIS_URL is not set: nothing is cached.');
}

const app = createApp(config, {
  db,
  cache: redis ? new RedisCache(redis) : noCache,
  // Replace with the PaymentProvider of your payment gateway before taking real orders.
  payments: new SandboxPaymentProvider(),
});
const server = app.listen(config.port, () => {
  console.log(`Store API ready at http://localhost:${(server.address() as AddressInfo).port}/api/v1`);
});

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.once(signal, () => {
    server.close(async () => {
      await db.end();
      await redis?.quit();
      process.exit(0);
    });
  });
}
