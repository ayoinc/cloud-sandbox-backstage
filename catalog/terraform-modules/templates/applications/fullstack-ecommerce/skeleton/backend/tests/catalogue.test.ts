import { afterEach, describe, expect, it } from 'vitest';
import { seedSampleData } from '../src/db.js';
import { startTestApp, type TestApp } from './helpers.js';

let app: TestApp;
afterEach(() => app.close());

describe('catalogue', () => {
  it('lists products by name, a page at a time', async () => {
    app = await startTestApp();
    for (const name of ['Cup', 'Apron', 'Bowl']) await app.addProduct({ name });

    const first = await app.call('GET', '/products?limit=2');
    expect(first.status).toBe(200);
    expect(first.body.products.map((product: { name: string }) => product.name)).toEqual(['Apron', 'Bowl']);

    const second = await app.call('GET', '/products?limit=2&offset=2');
    expect(second.body.products.map((product: { name: string }) => product.name)).toEqual(['Cup']);
  });

  it('shows one product, and answers 404 for an unknown one', async () => {
    app = await startTestApp();
    const { id } = await app.addProduct({ name: 'Lamp', priceCents: 3900 });

    const found = await app.call('GET', `/products/${id}`);
    expect(found.body.product).toMatchObject({ id, name: 'Lamp', priceCents: 3900, available: true });

    expect((await app.call('GET', '/products/00000000-0000-4000-8000-000000000000')).status).toBe(404);
    expect((await app.call('GET', '/products/not-an-id')).status).toBe(404);
  });

  it('rejects an invalid page size', async () => {
    app = await startTestApp();

    expect((await app.call('GET', '/products?limit=0')).status).toBe(400);
  });

  it('tells the frontend which features are on', async () => {
    app = await startTestApp({ search: true, reviews: true });

    const { body } = await app.call('GET', '/config');
    expect(body.features).toMatchObject({ search: true, reviews: true, payments: false });
  });

  it('fills an empty catalogue with sample products, once', async () => {
    app = await startTestApp();

    await seedSampleData(app.db);
    await seedSampleData(app.db);

    expect((await app.call('GET', '/products')).body.products).toHaveLength(6);
  });
});

describe('search', () => {
  it('finds products by name or description when on', async () => {
    app = await startTestApp({ search: true });
    await app.addProduct({ name: 'Desk Lamp', description: 'Bright' });
    await app.addProduct({ name: 'Mug', description: 'Goes well with a lamp' });
    await app.addProduct({ name: 'Blanket', description: '100% wool' });

    const lamps = await app.call('GET', '/products?q=LAMP');
    expect(lamps.body.products.map((product: { name: string }) => product.name)).toEqual(['Desk Lamp', 'Mug']);

    // A wildcard character in the search text is taken literally.
    expect((await app.call('GET', '/products?q=100%25')).body.products).toHaveLength(1);
    expect((await app.call('GET', '/products?q=%25')).body.products).toHaveLength(1);
  });

  it('ignores the search text when off', async () => {
    app = await startTestApp({ search: false });
    await app.addProduct({ name: 'Desk Lamp' });
    await app.addProduct({ name: 'Mug' });

    expect((await app.call('GET', '/products?q=lamp')).body.products).toHaveLength(2);
  });
});

describe('inventory', () => {
  it('shows stock levels when on', async () => {
    app = await startTestApp({ inventory: true });
    const inStock = await app.addProduct({ stock: 3 });
    const soldOut = await app.addProduct({ stock: 0 });

    expect((await app.call('GET', `/products/${inStock.id}`)).body.product).toMatchObject({ stock: 3, available: true });
    expect((await app.call('GET', `/products/${soldOut.id}`)).body.product).toMatchObject({ stock: 0, available: false });
  });

  it('hides stock levels and sells everything when off', async () => {
    app = await startTestApp({ inventory: false });
    const { id } = await app.addProduct({ stock: 0 });

    const { product } = (await app.call('GET', `/products/${id}`)).body;
    expect(product.available).toBe(true);
    expect(product).not.toHaveProperty('stock');
  });
});
