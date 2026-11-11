import { randomUUID } from 'node:crypto';
import type { Db } from './db.js';
import type { PaymentProvider } from './payments.js';

export interface Product {
  id: string;
  name: string;
  description: string;
  priceCents: number;
  imageUrl: string | null;
  stock: number;
  createdAt: string;
}

export interface ProductInput {
  name: string;
  description: string;
  priceCents: number;
  imageUrl?: string | null;
  stock: number;
}

export interface Review {
  id: string;
  productId: string;
  author: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface Rating {
  average: number | null;
  count: number;
}

export interface OrderItem {
  productId: string | null;
  productName: string;
  unitPriceCents: number;
  quantity: number;
}

export interface Order {
  id: string;
  customerEmail: string;
  /** "paid" when a payment was taken, "pending" when the store has no payment step. */
  status: string;
  totalCents: number;
  items: OrderItem[];
  createdAt: string;
}

export interface SalesSummary {
  orders: number;
  revenueCents: number;
  averageOrderCents: number;
  topProducts: { name: string; unitsSold: number }[];
}

/** An order that cannot be placed; `status` is the HTTP status to answer with. */
export class OrderError extends Error {
  constructor(
    readonly status: 402 | 409 | 422,
    message: string,
  ) {
    super(message);
  }
}

interface ProductRow {
  id: string;
  name: string;
  description: string;
  price_cents: number;
  image_url: string | null;
  stock: number;
  created_at: Date;
}

function toProduct(row: ProductRow): Product {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    priceCents: row.price_cents,
    imageUrl: row.image_url,
    stock: row.stock,
    createdAt: row.created_at.toISOString(),
  };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Reads and writes the data of the store. */
export class Store {
  constructor(private readonly db: Db) {}

  /** Lists products by name. `search` keeps those whose name or description contains it. */
  async listProducts(options: { search?: string; limit: number; offset: number }): Promise<Product[]> {
    const pattern = options.search ? `%${options.search.replace(/[\\%_]/g, '\\$&')}%` : null;
    const { rows } = await this.db.query<ProductRow>(
      `select * from products
       where $1::text is null or name ilike $1 or description ilike $1
       order by name, id
       limit $2 offset $3`,
      [pattern, options.limit, options.offset],
    );
    return rows.map(toProduct);
  }

  async getProduct(id: string): Promise<Product | undefined> {
    if (!UUID.test(id)) return undefined;
    const { rows } = await this.db.query<ProductRow>('select * from products where id = $1', [id]);
    return rows[0] && toProduct(rows[0]);
  }

  async createProduct(input: ProductInput): Promise<Product> {
    const { rows } = await this.db.query<ProductRow>(
      `insert into products (id, name, description, price_cents, image_url, stock)
       values ($1, $2, $3, $4, $5, $6) returning *`,
      [randomUUID(), input.name, input.description, input.priceCents, input.imageUrl ?? null, input.stock],
    );
    return toProduct(rows[0]!);
  }

  async updateProduct(id: string, input: ProductInput): Promise<Product | undefined> {
    if (!UUID.test(id)) return undefined;
    const { rows } = await this.db.query<ProductRow>(
      `update products set name = $2, description = $3, price_cents = $4, image_url = $5, stock = $6
       where id = $1 returning *`,
      [id, input.name, input.description, input.priceCents, input.imageUrl ?? null, input.stock],
    );
    return rows[0] && toProduct(rows[0]);
  }

  async deleteProduct(id: string): Promise<boolean> {
    if (!UUID.test(id)) return false;
    const result = await this.db.query('delete from products where id = $1', [id]);
    return result.rowCount === 1;
  }

  async listReviews(productId: string): Promise<Review[]> {
    if (!UUID.test(productId)) return [];
    const { rows } = await this.db.query<{
      id: string;
      product_id: string;
      author: string;
      rating: number;
      comment: string;
      created_at: Date;
    }>('select * from reviews where product_id = $1 order by created_at desc, id', [productId]);
    return rows.map(row => ({
      id: row.id,
      productId: row.product_id,
      author: row.author,
      rating: row.rating,
      comment: row.comment,
      createdAt: row.created_at.toISOString(),
    }));
  }

  async addReview(productId: string, input: { author: string; rating: number; comment: string }): Promise<Review> {
    const { rows } = await this.db.query<{ id: string; created_at: Date }>(
      `insert into reviews (id, product_id, author, rating, comment)
       values ($1, $2, $3, $4, $5) returning id, created_at`,
      [randomUUID(), productId, input.author, input.rating, input.comment],
    );
    return { id: rows[0]!.id, productId, ...input, createdAt: rows[0]!.created_at.toISOString() };
  }

  async getRating(productId: string): Promise<Rating> {
    const { rows } = await this.db.query<{ average: string | null; count: string }>(
      'select round(avg(rating), 1) as average, count(*) as count from reviews where product_id = $1',
      [productId],
    );
    const row = rows[0]!;
    return { average: row.average === null ? null : Number(row.average), count: Number(row.count) };
  }

  /**
   * Places an order in one transaction: prices come from the catalogue, with
   * `trackStock` the stock is checked and reduced, and with `payments` the
   * total is charged before the order is kept. Throws OrderError when the
   * order cannot be placed; nothing is stored then.
   */
  async placeOrder(
    input: { customerEmail: string; items: { productId: string; quantity: number }[]; paymentToken?: string },
    options: { trackStock: boolean; payments?: PaymentProvider },
  ): Promise<Order> {
    const quantities = new Map<string, number>();
    for (const item of input.items) {
      quantities.set(item.productId, (quantities.get(item.productId) ?? 0) + item.quantity);
    }

    const client = await this.db.connect();
    try {
      await client.query('begin');
      // Locks the rows in a fixed order, so two orders for the same products cannot deadlock.
      const { rows } = await client.query<ProductRow>(
        'select * from products where id = any($1::uuid[]) order by id for update',
        [[...quantities.keys()].filter(id => UUID.test(id))],
      );
      const products = new Map(rows.map(row => [row.id, row]));

      const items: OrderItem[] = [];
      for (const [productId, quantity] of quantities) {
        const product = products.get(productId);
        if (!product) throw new OrderError(422, `Product ${productId} does not exist.`);
        if (options.trackStock && product.stock < quantity) {
          throw new OrderError(409, `Only ${product.stock} of "${product.name}" left in stock.`);
        }
        items.push({ productId, productName: product.name, unitPriceCents: product.price_cents, quantity });
      }
      const totalCents = items.reduce((sum, item) => sum + item.unitPriceCents * item.quantity, 0);

      const id = randomUUID();
      let paymentReference: string | null = null;
      if (options.payments) {
        if (!input.paymentToken) throw new OrderError(422, 'paymentToken is required.');
        const result = await options.payments.charge({ orderId: id, amountCents: totalCents, paymentToken: input.paymentToken });
        if (result.status === 'declined') throw new OrderError(402, result.reason);
        paymentReference = result.reference;
      }
      const status = options.payments ? 'paid' : 'pending';

      const inserted = await client.query<{ created_at: Date }>(
        `insert into orders (id, customer_email, status, total_cents, payment_reference)
         values ($1, $2, $3, $4, $5) returning created_at`,
        [id, input.customerEmail, status, totalCents, paymentReference],
      );
      for (const item of items) {
        await client.query(
          `insert into order_items (order_id, product_id, product_name, unit_price_cents, quantity)
           values ($1, $2, $3, $4, $5)`,
          [id, item.productId, item.productName, item.unitPriceCents, item.quantity],
        );
        if (options.trackStock) {
          await client.query('update products set stock = stock - $2 where id = $1', [item.productId, item.quantity]);
        }
      }
      await client.query('commit');
      return {
        id,
        customerEmail: input.customerEmail,
        status,
        totalCents,
        items,
        createdAt: inserted.rows[0]!.created_at.toISOString(),
      };
    } catch (error) {
      await client.query('rollback');
      throw error;
    } finally {
      client.release();
    }
  }

  async getOrder(id: string): Promise<Order | undefined> {
    if (!UUID.test(id)) return undefined;
    const orders = await this.db.query<{
      id: string;
      customer_email: string;
      status: string;
      total_cents: number;
      created_at: Date;
    }>('select * from orders where id = $1', [id]);
    const order = orders.rows[0];
    if (!order) return undefined;
    const items = await this.db.query<{
      product_id: string | null;
      product_name: string;
      unit_price_cents: number;
      quantity: number;
    }>('select * from order_items where order_id = $1 order by product_name', [id]);
    return {
      id: order.id,
      customerEmail: order.customer_email,
      status: order.status,
      totalCents: order.total_cents,
      items: items.rows.map(row => ({
        productId: row.product_id,
        productName: row.product_name,
        unitPriceCents: row.unit_price_cents,
        quantity: row.quantity,
      })),
      createdAt: order.created_at.toISOString(),
    };
  }

  /** Sales figures over all orders, with the five best-selling products. */
  async salesSummary(): Promise<SalesSummary> {
    const totals = await this.db.query<{ orders: string; revenue: string }>(
      'select count(*) as orders, coalesce(sum(total_cents), 0) as revenue from orders',
    );
    const top = await this.db.query<{ name: string; units: string }>(
      `select product_name as name, sum(quantity) as units from order_items
       group by product_name order by units desc, name limit 5`,
    );
    const orders = Number(totals.rows[0]!.orders);
    const revenueCents = Number(totals.rows[0]!.revenue);
    return {
      orders,
      revenueCents,
      averageOrderCents: orders === 0 ? 0 : Math.round(revenueCents / orders),
      topProducts: top.rows.map(row => ({ name: row.name, unitsSold: Number(row.units) })),
    };
  }
}
