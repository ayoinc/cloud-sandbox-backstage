import type { Redis } from 'ioredis';

/** Keeps the answers of catalogue reads until the catalogue changes. */
export interface Cache {
  /** Returns the cached value for key, or computes and stores it. */
  wrap<T>(key: string, compute: () => Promise<T>): Promise<T>;
  /** Drops everything: called after any change to products, stock or reviews. */
  invalidate(): Promise<void>;
}

/** Used when caching is off: always computes. */
export const noCache: Cache = {
  wrap: (_key, compute) => compute(),
  invalidate: async () => {},
};

const GENERATION_KEY = 'catalogue:generation';

/**
 * A cache in Redis shared by all replicas. Entries carry the generation of
 * the catalogue they were computed from; a change starts a new generation, so
 * older entries are never read again and expire on their own.
 */
export class RedisCache implements Cache {
  constructor(
    private readonly redis: Redis,
    private readonly ttlSeconds = 60,
  ) {}

  async wrap<T>(key: string, compute: () => Promise<T>): Promise<T> {
    const generation = (await this.redis.get(GENERATION_KEY)) ?? '0';
    const cacheKey = `catalogue:${generation}:${key}`;
    const cached = await this.redis.get(cacheKey);
    if (cached !== null) return JSON.parse(cached) as T;

    const value = await compute();
    await this.redis.set(cacheKey, JSON.stringify(value), 'EX', this.ttlSeconds);
    return value;
  }

  async invalidate(): Promise<void> {
    await this.redis.incr(GENERATION_KEY);
  }
}
