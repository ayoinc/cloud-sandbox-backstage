import { afterEach, describe, expect, it } from 'vitest';
import { ADMIN_TOKEN, startTestApp, type TestApp } from './helpers.js';

let app: TestApp;
afterEach(() => app.close());

const lamp = { name: 'Lamp', description: 'A lamp', priceCents: 3900, stock: 5 };

describe('product management', () => {
  it('creates, changes and deletes products', async () => {
    app = await startTestApp({ productManagement: true, inventory: true });

    const created = await app.call('POST', '/admin/products', lamp, ADMIN_TOKEN);
    expect(created.status).toBe(201);
    const { id } = created.body.product;

    const changed = await app.call('PUT', `/admin/products/${id}`, { ...lamp, priceCents: 3500 }, ADMIN_TOKEN);
    expect(changed.body.product.priceCents).toBe(3500);
    expect((await app.call('GET', `/products/${id}`)).body.product).toMatchObject({ name: 'Lamp', priceCents: 3500, stock: 5 });

    expect((await app.call('DELETE', `/admin/products/${id}`, undefined, ADMIN_TOKEN)).status).toBe(204);
    expect((await app.call('GET', `/products/${id}`)).status).toBe(404);
    expect((await app.call('DELETE', `/admin/products/${id}`, undefined, ADMIN_TOKEN)).status).toBe(404);
  });

  it('rejects invalid products', async () => {
    app = await startTestApp({ productManagement: true });

    const result = await app.call('POST', '/admin/products', { ...lamp, priceCents: -1 }, ADMIN_TOKEN);

    expect(result.status).toBe(400);
    expect(result.body.details.fieldErrors).toHaveProperty('priceCents');
  });

  it('needs the admin token', async () => {
    app = await startTestApp({ productManagement: true });

    expect((await app.call('POST', '/admin/products', lamp)).status).toBe(401);
    expect((await app.call('POST', '/admin/products', lamp, 'wrong-token')).status).toBe(401);
  });

  it('is closed while no admin token is configured', async () => {
    app = await startTestApp({ productManagement: true }, { adminToken: undefined });

    expect((await app.call('POST', '/admin/products', lamp, ADMIN_TOKEN)).status).toBe(503);
  });

  it('does not exist when off', async () => {
    app = await startTestApp({ productManagement: false });

    expect((await app.call('POST', '/admin/products', lamp, ADMIN_TOKEN)).status).toBe(404);
  });
});

describe('analytics', () => {
  it('summarises the sales when on', async () => {
    app = await startTestApp({ analytics: true });
    const mug = await app.addProduct({ name: 'Mug', priceCents: 1000 });
    const pen = await app.addProduct({ name: 'Pen', priceCents: 200 });
    const order = (items: { productId: string; quantity: number }[]) =>
      app.call('POST', '/orders', { customerEmail: 'customer@example.com', items });
    await order([{ productId: mug.id, quantity: 1 }]);
    await order([
      { productId: mug.id, quantity: 2 },
      { productId: pen.id, quantity: 5 },
    ]);

    const result = await app.call('GET', '/admin/analytics/summary', undefined, ADMIN_TOKEN);

    expect(result.body.summary).toEqual({
      orders: 2,
      revenueCents: 4000,
      averageOrderCents: 2000,
      topProducts: [
        { name: 'Pen', unitsSold: 5 },
        { name: 'Mug', unitsSold: 3 },
      ],
    });
  });

  it('needs the admin token', async () => {
    app = await startTestApp({ analytics: true });

    expect((await app.call('GET', '/admin/analytics/summary')).status).toBe(401);
  });

  it('does not exist when off', async () => {
    app = await startTestApp({ analytics: false, productManagement: true });

    expect((await app.call('GET', '/admin/analytics/summary', undefined, ADMIN_TOKEN)).status).toBe(404);
  });
});
