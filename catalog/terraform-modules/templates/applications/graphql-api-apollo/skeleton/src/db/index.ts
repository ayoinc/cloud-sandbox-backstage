import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import knex, { type Knex } from 'knex';
import type { Config } from '../config.js';
import { migrationSource } from './migrations.js';

/** Opens the database named in the configuration. */
export function createDb(database: Config['database']): Knex {
  if (database.client === 'better-sqlite3') {
    if (database.url !== ':memory:') mkdirSync(dirname(database.url), { recursive: true });
    return knex({
      client: database.client,
      connection: { filename: database.url },
      useNullAsDefault: true,
    });
  }
  return knex({
    client: database.client,
    connection: database.url,
    pool: { min: 0, max: 10 },
  });
}

/** Brings the schema up to date. Safe to call on every start. */
export async function migrate(db: Knex): Promise<void> {
  await db.migrate.latest({ migrationSource });
}
