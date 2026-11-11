import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { defaults } from '../src/defaults.js';

const base = { AUTH_ENABLED: 'false' };

describe('loadConfig', () => {
  it('falls back to the defaults', () => {
    const config = loadConfig(base);

    expect(config.port).toBe(4000);
    expect(config.database).toEqual({ client: defaults.databaseClient, url: defaults.databaseUrl });
    expect(config.subscriptions).toBe(defaults.subscriptions);
    expect(config.playground).toBe(defaults.playground);
    expect(config.queryComplexityLimit).toBe(defaults.queryComplexityLimit);
    expect(config.cache.enabled).toBe(defaults.cacheEnabled);
    expect(config.metrics).toBe(defaults.metrics);
    expect(config.tracing.enabled).toBe(defaults.tracing);
  });

  it('lets environment variables override the defaults', () => {
    const config = loadConfig({
      ...base,
      PORT: '8080',
      DATABASE_URL: 'somewhere-else',
      SUBSCRIPTIONS_ENABLED: String(!defaults.subscriptions),
      PLAYGROUND_ENABLED: String(!defaults.playground),
      QUERY_COMPLEXITY_LIMIT: '42',
      CACHE_ENABLED: String(!defaults.cacheEnabled),
      CACHE_TTL_SECONDS: '5',
      REDIS_URL: 'redis://cache:6379',
      METRICS_ENABLED: String(!defaults.metrics),
      TRACING_ENABLED: String(!defaults.tracing),
    });

    expect(config.port).toBe(8080);
    expect(config.database.url).toBe('somewhere-else');
    expect(config.subscriptions).toBe(!defaults.subscriptions);
    expect(config.playground).toBe(!defaults.playground);
    expect(config.queryComplexityLimit).toBe(42);
    expect(config.cache).toEqual({ enabled: !defaults.cacheEnabled, ttlSeconds: 5, redisUrl: 'redis://cache:6379' });
    expect(config.metrics).toBe(!defaults.metrics);
    expect(config.tracing.enabled).toBe(!defaults.tracing);
  });

  it('rejects values that are not booleans or integers', () => {
    expect(() => loadConfig({ ...base, METRICS_ENABLED: 'yes' })).toThrow('METRICS_ENABLED');
    expect(() => loadConfig({ ...base, PORT: 'http' })).toThrow('PORT');
    expect(() => loadConfig({ ...base, AUTH_PROVIDER: 'saml' })).toThrow('AUTH_PROVIDER');
  });

  it('needs a secret for the jwt provider', () => {
    const env = { AUTH_ENABLED: 'true', AUTH_PROVIDER: 'jwt' };

    expect(() => loadConfig(env)).toThrow('JWT_SECRET');
    expect(loadConfig({ ...env, JWT_SECRET: 'secret' }).auth).toMatchObject({ enabled: true, jwtSecret: 'secret' });
  });

  it('needs an issuer for the oauth2 provider and derives the JWKS address from it', () => {
    const env = { AUTH_ENABLED: 'true', AUTH_PROVIDER: 'oauth2' };

    expect(() => loadConfig(env)).toThrow('AUTH_ISSUER');
    expect(loadConfig({ ...env, AUTH_ISSUER: 'https://id.example.com/tenant' }).auth.jwksUri).toBe(
      'https://id.example.com/tenant/.well-known/jwks.json',
    );
    expect(
      loadConfig({ ...env, AUTH_ISSUER: 'https://id.example.com', AUTH_JWKS_URI: 'https://id.example.com/keys' }).auth
        .jwksUri,
    ).toBe('https://id.example.com/keys');
  });
});
