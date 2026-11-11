import { applyD1Migrations } from 'cloudflare:test';
import { env } from 'cloudflare:workers';

// Runs before every test file. Applying migrations is idempotent: those
// already applied are skipped.
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
