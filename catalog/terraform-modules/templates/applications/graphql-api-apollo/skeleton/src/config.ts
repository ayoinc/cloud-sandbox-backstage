import { defaults } from './defaults.js';

export type DatabaseClient = 'pg' | 'mysql2' | 'better-sqlite3';

export interface AuthConfig {
  enabled: boolean;
  provider: 'jwt' | 'oauth2';
  /** When true, changing data needs the admin role, not just a valid token. */
  rbac: boolean;
  /** Name of the token claim that lists the roles of the caller. */
  rolesClaim: string;
  /** Shared secret of the HS256 tokens (provider jwt). */
  jwtSecret?: string;
  issuer?: string;
  audience?: string;
  /** Where the signing keys of the identity provider are published (provider oauth2). */
  jwksUri?: string;
}

export interface Config {
  nodeEnv: string;
  port: number;
  database: { client: DatabaseClient; url: string };
  subscriptions: boolean;
  playground: boolean;
  queryComplexityLimit: number;
  cache: { enabled: boolean; ttlSeconds: number; redisUrl?: string };
  auth: AuthConfig;
  metrics: boolean;
  tracing: { enabled: boolean; endpoint?: string };
}

type Env = Record<string, string | undefined>;

function flag(env: Env, name: string, fallback: boolean): boolean {
  const value = env[name];
  if (value === undefined || value === '') return fallback;
  if (value === 'true' || value === '1') return true;
  if (value === 'false' || value === '0') return false;
  throw new Error(`${name} must be true or false, got "${value}"`);
}

function integer(env: Env, name: string, fallback: number): number {
  const value = env[name];
  if (value === undefined || value === '') return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${name} must be a non-negative integer, got "${value}"`);
  }
  return parsed;
}

function text(env: Env, name: string): string | undefined {
  const value = env[name];
  return value === undefined || value === '' ? undefined : value;
}

function loadAuth(env: Env): AuthConfig {
  const provider = text(env, 'AUTH_PROVIDER') ?? defaults.authProvider;
  if (provider !== 'jwt' && provider !== 'oauth2') {
    throw new Error(`AUTH_PROVIDER must be jwt or oauth2, got "${provider}"`);
  }
  const auth: AuthConfig = {
    enabled: flag(env, 'AUTH_ENABLED', defaults.authEnabled),
    provider,
    rbac: flag(env, 'AUTH_RBAC', defaults.rbac),
    rolesClaim: text(env, 'AUTH_ROLES_CLAIM') ?? 'roles',
    jwtSecret: text(env, 'JWT_SECRET'),
    issuer: text(env, 'AUTH_ISSUER'),
    audience: text(env, 'AUTH_AUDIENCE'),
    jwksUri: text(env, 'AUTH_JWKS_URI'),
  };
  if (!auth.enabled) return auth;

  if (auth.provider === 'jwt' && !auth.jwtSecret) {
    throw new Error('JWT_SECRET is required when AUTH_ENABLED=true and AUTH_PROVIDER=jwt');
  }
  if (auth.provider === 'oauth2') {
    if (!auth.issuer) {
      throw new Error('AUTH_ISSUER is required when AUTH_ENABLED=true and AUTH_PROVIDER=oauth2');
    }
    auth.jwksUri ??= new URL('.well-known/jwks.json', auth.issuer.endsWith('/') ? auth.issuer : `${auth.issuer}/`).href;
  }
  return auth;
}

/** Reads the configuration from environment variables. Throws when a value is invalid. */
export function loadConfig(env: Env = process.env): Config {
  return {
    nodeEnv: text(env, 'NODE_ENV') ?? 'development',
    port: integer(env, 'PORT', 4000),
    database: {
      client: defaults.databaseClient,
      url: text(env, 'DATABASE_URL') ?? defaults.databaseUrl,
    },
    subscriptions: flag(env, 'SUBSCRIPTIONS_ENABLED', defaults.subscriptions),
    playground: flag(env, 'PLAYGROUND_ENABLED', defaults.playground),
    queryComplexityLimit: integer(env, 'QUERY_COMPLEXITY_LIMIT', defaults.queryComplexityLimit),
    cache: {
      enabled: flag(env, 'CACHE_ENABLED', defaults.cacheEnabled),
      ttlSeconds: integer(env, 'CACHE_TTL_SECONDS', 30),
      redisUrl: text(env, 'REDIS_URL'),
    },
    auth: loadAuth(env),
    metrics: flag(env, 'METRICS_ENABLED', defaults.metrics),
    tracing: {
      enabled: flag(env, 'TRACING_ENABLED', defaults.tracing),
      endpoint: text(env, 'OTEL_EXPORTER_OTLP_ENDPOINT'),
    },
  };
}
