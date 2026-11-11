import { randomUUID } from 'node:crypto';
import pg from 'pg';

export type Db = pg.Pool;

export function createDb(databaseUrl: string): Db {
  return new pg.Pool({ connectionString: databaseUrl, max: 10 });
}

// Migrations run in this order, each once. Append new ones; never edit one
// that has already run somewhere.
const migrations: { name: string; sql: string }[] = [
  {
    name: '001_initial_schema',
    sql: `
      create table products (
        id uuid primary key,
        name text not null,
        description text not null default '',
        price_cents integer not null check (price_cents >= 0),
        image_url text,
        stock integer not null default 0 check (stock >= 0),
        created_at timestamptz not null default now()
      );
      create table reviews (
        id uuid primary key,
        product_id uuid not null references products (id) on delete cascade,
        author text not null,
        rating integer not null check (rating between 1 and 5),
        comment text not null default '',
        created_at timestamptz not null default now()
      );
      create index reviews_product_id on reviews (product_id);
      create table orders (
        id uuid primary key,
        customer_email text not null,
        status text not null,
        total_cents integer not null,
        payment_reference text,
        created_at timestamptz not null default now()
      );
      create table order_items (
        order_id uuid not null references orders (id) on delete cascade,
        product_id uuid references products (id) on delete set null,
        product_name text not null,
        unit_price_cents integer not null,
        quantity integer not null check (quantity > 0)
      );
      create index order_items_order_id on order_items (order_id);
    `,
  },
];

/** Brings the schema up to date. Safe to call on every start and from several replicas. */
export async function migrate(db: Db): Promise<void> {
  const client = await db.connect();
  try {
    await client.query('begin');
    // One replica migrates at a time; the others wait here and then find nothing to do.
    await client.query('select pg_advisory_xact_lock(727274)');
    await client.query('create table if not exists schema_migrations (name text primary key)');
    const applied = await client.query<{ name: string }>('select name from schema_migrations');
    const done = new Set(applied.rows.map(row => row.name));
    for (const migration of migrations) {
      if (done.has(migration.name)) continue;
      await client.query(migration.sql);
      await client.query('insert into schema_migrations (name) values ($1)', [migration.name]);
    }
    await client.query('commit');
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally {
    client.release();
  }
}

const sampleProducts = [
  { name: 'Canvas Backpack', description: 'A 20 litre backpack with a padded laptop sleeve.', priceCents: 5900, stock: 25 },
  { name: 'Ceramic Mug', description: 'A 350 ml stoneware mug, dishwasher safe.', priceCents: 1400, stock: 80 },
  { name: 'Desk Lamp', description: 'An LED lamp with three brightness levels.', priceCents: 3900, stock: 15 },
  { name: 'Notebook Set', description: 'Three A5 notebooks with dotted pages.', priceCents: 1800, stock: 60 },
  { name: 'Steel Water Bottle', description: 'Keeps drinks cold for 24 hours. 750 ml.', priceCents: 2400, stock: 40 },
  { name: 'Wool Blanket', description: 'A 130 x 180 cm throw made of merino wool.', priceCents: 8900, stock: 0 },
];

/** Adds sample products to an empty catalogue, so a new store has something to show. */
export async function seedSampleData(db: Db): Promise<void> {
  const { rows } = await db.query<{ count: string }>('select count(*) from products');
  if (Number(rows[0]?.count) > 0) return;
  for (const product of sampleProducts) {
    await db.query(
      'insert into products (id, name, description, price_cents, stock) values ($1, $2, $3, $4, $5)',
      [randomUUID(), product.name, product.description, product.priceCents, product.stock],
    );
  }
}
