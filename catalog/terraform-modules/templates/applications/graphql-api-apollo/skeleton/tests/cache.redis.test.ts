import { Redis } from 'ioredis';
import { afterAll, describe, expect, it } from 'vitest';
import { RedisCache } from '../src/cache.js';
import { startTestServer } from './helpers.js';

const redisUrl = process.env.REDIS_URL;

// Needs a Redis server: runs in the pipeline and wherever REDIS_URL is set.
describe.skipIf(!redisUrl)('Redis cache', () => {
  const redis = new Redis(redisUrl ?? '', { lazyConnect: true });
  const cache = new RedisCache(redis);
  afterAll(() => redis.quit());

  it('stores, expires and deletes entries', async () => {
    const key = `test:${Date.now()}`;

    expect(await cache.get(key)).toBeUndefined();
    await cache.set(key, 'value', { ttl: 60 });
    expect(await cache.get(key)).toBe('value');
    expect(await redis.ttl(key)).toBeGreaterThan(0);
    expect(await cache.delete(key)).toBe(true);
    expect(await cache.delete(key)).toBe(false);
  });

  it('holds the cached responses of the API', async () => {
    await redis.flushdb();
    const server = await startTestServer({ cache: { enabled: true, ttlSeconds: 60 } }, { cache });
    try {
      await server.query('{ products { name } }');

      expect(await redis.dbsize()).toBe(1);
    } finally {
      await server.close();
    }
  });
});
