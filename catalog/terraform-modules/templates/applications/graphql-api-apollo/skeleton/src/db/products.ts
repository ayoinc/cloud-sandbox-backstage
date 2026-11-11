import { randomUUID } from 'node:crypto';
import type { Knex } from 'knex';

export interface Product {
  id: string;
  name: string;
  description: string | null;
  priceCents: number;
  inStock: boolean;
  createdAt: string;
}

export interface NewProduct {
  name: string;
  description?: string | null;
  priceCents: number;
  inStock?: boolean | null;
}

interface ProductRow {
  id: string;
  name: string;
  description: string | null;
  price_cents: number;
  // Booleans come back as 0 or 1 from MySQL and SQLite.
  in_stock: boolean | number;
  created_at: string;
}

function toProduct(row: ProductRow): Product {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    priceCents: row.price_cents,
    inStock: Boolean(row.in_stock),
    createdAt: row.created_at,
  };
}

/** Reads and writes products. */
export class ProductRepository {
  constructor(private readonly db: Knex) {}

  /** Returns products, newest first. */
  async list(limit: number, offset: number): Promise<Product[]> {
    const rows = await this.db<ProductRow>('products')
      .select()
      .orderBy([
        { column: 'created_at', order: 'desc' },
        { column: 'id', order: 'asc' },
      ])
      .limit(limit)
      .offset(offset);
    return rows.map(toProduct);
  }

  async get(id: string): Promise<Product | undefined> {
    const row = await this.db<ProductRow>('products').where({ id }).first();
    return row ? toProduct(row) : undefined;
  }

  async create(input: NewProduct): Promise<Product> {
    const row: ProductRow = {
      id: randomUUID(),
      name: input.name,
      description: input.description ?? null,
      price_cents: input.priceCents,
      in_stock: input.inStock ?? true,
      created_at: new Date().toISOString(),
    };
    await this.db<ProductRow>('products').insert(row);
    return toProduct(row);
  }

  /** Deletes a product. Returns false when there was none with that ID. */
  async delete(id: string): Promise<boolean> {
    const deleted = await this.db<ProductRow>('products').where({ id }).delete();
    return deleted > 0;
  }
}
