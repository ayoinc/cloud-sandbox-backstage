import { Redis } from 'ioredis';
import { afterAll, describe, expect, it } from 'vitest';
import { noCache, RedisCache } from '../src/cache.js';
import { ADMIN_TOKEN, startTestApp } from './helpers.js';

describe('without a cache', () => {
  it('computes every time', async () => {
    let computed = 0;
    const compute = async () => ++computed;

    expect(await noCache.wrap('key', compute)).toBe(1);
    expect(await noCache.wrap('key', compute)).toBe(2);
  });
});

const redisUrl = process.env.REDIS_URL;

// Needs a Redis server: runs in the pipeline and wherever REDIS_URL is set.
describe.skipIf(!redisUrl)('Redis cache', () => {
  const redis = new Redis(redisUrl ?? '', { lazyConnect: true });
  const cache = new RedisCache(redis);
  afterAll(() => redis.quit());

  it('computes once until the catalogue changes', async () => {
    await redis.flushdb();
    let computed = 0;
    const compute = async () => ++computed;

    expect(await cache.wrap('key', compute)).toBe(1);
    expect(await cache.wrap('key', compute)).toBe(1);

    await cache.invalidate();
    expect(await cache.wrap('key', compute)).toBe(2);
  });

  it('serves the catalogue from the cache and refreshes it after a change', async () => {
    await redis.flushdb();
    const app = await startTestApp({ productManagement: true }, { cache });
    try {
      await app.addProduct({ name: 'Mug' });
      expect((await app.call('GET', '/products')).body.products).toHaveLength(1);

      // Added behind the back of the API: the cached list does not show it.
      await app.addProduct({ name: 'Lamp' });
      expect((await app.call('GET', '/products')).body.products).toHaveLength(1);

      // A change through the API starts a new cache generation.
      const pen = { name: 'Pen', description: '', priceCents: 200, stock: 1 };
      await app.call('POST', '/admin/products', pen, ADMIN_TOKEN);
      expect((await app.call('GET', '/products')).body.products).toHaveLength(3);
    } finally {
      await app.close();
    }
  });
});
