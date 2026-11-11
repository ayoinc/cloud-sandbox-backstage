import type { AddressInfo } from 'node:net';
import { Redis } from 'ioredis';
import { RedisCache } from './cache.js';
import { loadConfig } from './config.js';
import { createDb, migrate } from './db/index.js';
import { createServer } from './server.js';

const config = loadConfig();
const db = createDb(config.database);
await migrate(db);

const redis = config.cache.enabled && config.cache.redisUrl ? new Redis(config.cache.redisUrl) : undefined;
if (config.cache.enabled && !redis) {
  console.warn('REDIS_URL is not set: responses are cached in the memory of this process.');
}

const server = await createServer(config, { db, cache: redis && new RedisCache(redis) });
server.httpServer.listen(config.port, () => {
  const { port } = server.httpServer.address() as AddressInfo;
  console.log(`GraphQL API ready at http://localhost:${port}/graphql`);
});

async function shutdown(): Promise<void> {
  await server.stop();
  await db.destroy();
  await redis?.quit();
}
for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.once(signal, () => {
    shutdown().then(
      () => process.exit(0),
      error => {
        console.error(error);
        process.exit(1);
      },
    );
  });
}
