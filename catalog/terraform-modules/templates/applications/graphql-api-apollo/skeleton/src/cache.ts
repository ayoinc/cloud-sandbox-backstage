import type { KeyValueCache, KeyValueCacheSetOptions } from '@apollo/utils.keyvaluecache';
import type { Redis } from 'ioredis';

/** Stores Apollo Server's cache entries in Redis, so every replica shares them. */
export class RedisCache implements KeyValueCache<string> {
  constructor(private readonly redis: Redis) {}

  async get(key: string): Promise<string | undefined> {
    return (await this.redis.get(key)) ?? undefined;
  }

  async set(key: string, value: string, options?: KeyValueCacheSetOptions): Promise<void> {
    if (options?.ttl) {
      await this.redis.set(key, value, 'EX', options.ttl);
    } else {
      await this.redis.set(key, value);
    }
  }

  async delete(key: string): Promise<boolean> {
    return (await this.redis.del(key)) > 0;
  }
}
