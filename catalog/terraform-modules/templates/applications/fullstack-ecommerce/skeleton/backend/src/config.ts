import { featureDefaults, type Features } from './features.js';

export interface Config {
  port: number;
  databaseUrl: string;
  /** Redis for the catalogue cache. Without it nothing is cached. */
  redisUrl?: string;
  /** Bearer token of the admin API. Without it the admin API answers 503. */
  adminToken?: string;
  /** Fill an empty catalogue with sample products on start. */
  seedSampleData: boolean;
  features: Features;
}

type Env = Record<string, string | undefined>;

function flag(env: Env, name: string, fallback: boolean): boolean {
  const value = env[name];
  if (value === undefined || value === '') return fallback;
  if (value === 'true' || value === '1') return true;
  if (value === 'false' || value === '0') return false;
  throw new Error(`${name} must be true or false, got "${value}"`);
}

/** FEATURE_PRODUCT_MANAGEMENT for productManagement, and so on. */
function featureVariable(feature: string): string {
  return `FEATURE_${feature.replace(/[A-Z]/g, letter => `_${letter}`).toUpperCase()}`;
}

/** Reads the configuration from environment variables. Throws when a value is invalid. */
export function loadConfig(env: Env = process.env): Config {
  const port = Number(env.PORT ?? 8080);
  if (!Number.isInteger(port) || port < 0) throw new Error(`PORT must be a port number, got "${env.PORT}"`);

  const features = { ...featureDefaults };
  for (const feature of Object.keys(features) as (keyof Features)[]) {
    features[feature] = flag(env, featureVariable(feature), featureDefaults[feature]);
  }

  return {
    port,
    databaseUrl: env.DATABASE_URL || 'postgres://store:store@localhost:5432/store',
    redisUrl: env.REDIS_URL || undefined,
    adminToken: env.ADMIN_TOKEN || undefined,
    seedSampleData: flag(env, 'SEED_SAMPLE_DATA', env.NODE_ENV !== 'production'),
    features,
  };
}
