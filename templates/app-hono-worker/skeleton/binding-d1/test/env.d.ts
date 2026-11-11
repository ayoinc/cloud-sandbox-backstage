import type { D1Migration } from 'cloudflare:test';

declare global {
  namespace Cloudflare {
    interface Env {
      /** Set in vitest.config.ts; exists only in tests. */
      TEST_MIGRATIONS: D1Migration[];
    }
  }
}
