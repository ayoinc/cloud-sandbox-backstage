import type { DatabaseClient } from './config.js';

/** The values the configuration falls back to when a variable is not set. */
export interface Defaults {
  databaseClient: DatabaseClient;
  databaseUrl: string;
  subscriptions: boolean;
  playground: boolean;
  queryComplexityLimit: number;
  cacheEnabled: boolean;
  authEnabled: boolean;
  authProvider: 'jwt' | 'oauth2';
  rbac: boolean;
  metrics: boolean;
  tracing: boolean;
}

// Chosen when this API was created. Change a value here to change the default
// for every environment, or set the matching variable (see config.ts) to
// change it for one.
export const defaults: Defaults = {
{% if values.databaseType == 'postgresql' %}
  databaseClient: 'pg',
  databaseUrl: 'postgres://app:app@localhost:5432/app',
{% elif values.databaseType == 'mysql' %}
  databaseClient: 'mysql2',
  databaseUrl: 'mysql://app:app@localhost:3306/app',
{% else %}
  databaseClient: 'better-sqlite3',
  databaseUrl: './data/app.db',
{% endif %}
  subscriptions: ${{ 'true' if values.enableSubscriptions else 'false' }},
  playground: ${{ 'true' if values.enablePlayground else 'false' }},
  queryComplexityLimit: ${{ values.queryComplexity }},
  cacheEnabled: ${{ 'true' if values.enableCache else 'false' }},
  authEnabled: ${{ 'true' if values.enableAuth else 'false' }},
  authProvider: '${{ values.authProvider }}',
  rbac: ${{ 'true' if values.enableRBAC else 'false' }},
  metrics: ${{ 'true' if values.enableMetrics else 'false' }},
  tracing: ${{ 'true' if values.enableTracing else 'false' }},
};
