import { afterEach, describe, expect, it } from 'vitest';
import { startTestApp, type TestApp } from './helpers.js';

let app: TestApp;
afterEach(() => app.close());

const customerEmail = 'customer@example.com';

describe('orders', () => {
  it('places an order at catalogue prices and reads it back', async () => {
    app = await startTestApp();
    const mug = await app.addProduct({ name: 'Mug', priceCents: 1400 });
    const lamp = await app.addProduct({ name: 'Lamp', priceCents: 3900 });

    const placed = await app.call('POST', '/orders', {
      customerEmail,
      items: [
        { productId: mug.id, quantity: 2 },
        { productId: lamp.id, quantity: 1 },
      ],
    });

    expect(placed.status).toBe(201);
    expect(placed.body.order).toMatchObject({ customerEmail, status: 'pending', totalCents: 6700 });

    const read = await app.call('GET', `/orders/${placed.body.order.id}`);
    expect(read.body.order.items).toEqual([
      { productId: lamp.id, productName: 'Lamp', unitPriceCents: 3900, quantity: 1 },
      { productId: mug.id, productName: 'Mug', unitPriceCents: 1400, quantity: 2 },
    ]);
  });

  it('rejects invalid orders', async () => {
    app = await startTestApp();
    const { id } = await app.addProduct();

    const badEmail = await app.call('POST', '/orders', { customerEmail: 'nobody', items: [{ productId: id, quantity: 1 }] });
    expect(badEmail.status).toBe(400);

    const noItems = await app.call('POST', '/orders', { customerEmail, items: [] });
    expect(noItems.status).toBe(400);

    const unknownProduct = await app.call('POST', '/orders', {
      customerEmail,
      items: [{ productId: '00000000-0000-4000-8000-000000000000', quantity: 1 }],
    });
    expect(unknownProduct.status).toBe(422);

    expect((await app.call('GET', '/orders/00000000-0000-4000-8000-000000000000')).status).toBe(404);
  });
});

describe('orders with inventory', () => {
  it('reduces the stock, and refuses an order the stock cannot cover', async () => {
    app = await startTestApp({ inventory: true });
    const { id } = await app.addProduct({ stock: 3 });

    const first = await app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 2 }] });
    expect(first.status).toBe(201);
    expect((await app.store.getProduct(id))!.stock).toBe(1);

    const second = await app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 2 }] });
    expect(second.status).toBe(409);
    expect(second.body.error).toContain('Only 1');
    expect((await app.store.getProduct(id))!.stock).toBe(1);
  });

  it('never sells more than the stock when orders arrive together', async () => {
    app = await startTestApp({ inventory: true });
    const { id } = await app.addProduct({ stock: 5 });

    const results = await Promise.all(
      Array.from({ length: 8 }, () => app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 1 }] })),
    );

    expect(results.filter(result => result.status === 201)).toHaveLength(5);
    expect(results.filter(result => result.status === 409)).toHaveLength(3);
    expect((await app.store.getProduct(id))!.stock).toBe(0);
  });

  it('leaves the stock alone when inventory is off', async () => {
    app = await startTestApp({ inventory: false });
    const { id } = await app.addProduct({ stock: 0 });

    const placed = await app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 4 }] });

    expect(placed.status).toBe(201);
    expect((await app.store.getProduct(id))!.stock).toBe(0);
  });
});

describe('orders with payments', () => {
  it('takes the payment and marks the order paid', async () => {
    app = await startTestApp({ payments: true });
    const { id } = await app.addProduct({ priceCents: 2500 });

    const placed = await app.call('POST', '/orders', {
      customerEmail,
      items: [{ productId: id, quantity: 2 }],
      paymentToken: 'tok_visa',
    });

    expect(placed.status).toBe(201);
    expect(placed.body.order).toMatchObject({ status: 'paid', totalCents: 5000 });
    const stored = await app.db.query('select payment_reference from orders where id = $1', [placed.body.order.id]);
    expect(stored.rows[0].payment_reference).toMatch(/^sandbox_/);
  });

  it('needs a payment token', async () => {
    app = await startTestApp({ payments: true });
    const { id } = await app.addProduct();

    const placed = await app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 1 }] });

    expect(placed.status).toBe(422);
  });

  it('keeps nothing of an order whose payment is declined', async () => {
    app = await startTestApp({ payments: true, inventory: true });
    const { id } = await app.addProduct({ stock: 3 });

    const placed = await app.call('POST', '/orders', {
      customerEmail,
      items: [{ productId: id, quantity: 1 }],
      paymentToken: 'tok_declined',
    });

    expect(placed.status).toBe(402);
    expect((await app.db.query('select count(*) from orders')).rows[0].count).toBe('0');
    expect((await app.store.getProduct(id))!.stock).toBe(3);
  });

  it('charges the catalogue total to the payment provider', async () => {
    const charges: { amountCents: number; paymentToken: string }[] = [];
    app = await startTestApp(
      { payments: true },
      {
        payments: {
          async charge(charge) {
            charges.push(charge);
            return { status: 'succeeded', reference: 'ref-1' };
          },
        },
      },
    );
    const { id } = await app.addProduct({ priceCents: 1000 });

    await app.call('POST', '/orders', { customerEmail, items: [{ productId: id, quantity: 3 }], paymentToken: 'tok_1' });

    expect(charges).toMatchObject([{ amountCents: 3000, paymentToken: 'tok_1' }]);
  });
});
