import type { Knex } from 'knex';

interface Migration {
  name: string;
  up(db: Knex): Promise<void>;
  down(db: Knex): Promise<void>;
}

// Migrations run in this order. Append new ones; never edit one that has
// already run somewhere.
const migrations: Migration[] = [
  {
    name: '001_create_products',
    async up(db) {
      await db.schema.createTable('products', table => {
        table.string('id', 36).primary();
        table.string('name', 200).notNullable();
        table.text('description');
        table.integer('price_cents').notNullable();
        table.boolean('in_stock').notNullable().defaultTo(true);
        // ISO 8601 in UTC, which sorts chronologically as text.
        table.string('created_at', 30).notNullable().index();
      });
    },
    async down(db) {
      await db.schema.dropTable('products');
    },
  },
];

/** Feeds the migrations above to Knex, so they need no files on disk. */
export const migrationSource: Knex.MigrationSource<Migration> = {
  getMigrations: async () => migrations,
  getMigrationName: migration => migration.name,
  getMigration: async migration => migration,
};
