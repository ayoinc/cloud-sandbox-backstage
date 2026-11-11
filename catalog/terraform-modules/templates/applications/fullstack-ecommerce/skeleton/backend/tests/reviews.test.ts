import { afterEach, describe, expect, it } from 'vitest';
import { startTestApp, type TestApp } from './helpers.js';

let app: TestApp;
afterEach(() => app.close());

describe('reviews', () => {
  it('stores reviews and rates the product with their average', async () => {
    app = await startTestApp({ reviews: true });
    const { id } = await app.addProduct();

    expect((await app.call('GET', `/products/${id}`)).body.product.rating).toEqual({ average: null, count: 0 });

    const added = await app.call('POST', `/products/${id}/reviews`, { author: 'Ada', rating: 5, comment: 'Great' });
    expect(added.status).toBe(201);
    await app.call('POST', `/products/${id}/reviews`, { author: 'Grace', rating: 4 });

    const { reviews } = (await app.call('GET', `/products/${id}/reviews`)).body;
    expect(reviews.map((review: { author: string }) => review.author).sort()).toEqual(['Ada', 'Grace']);
    expect((await app.call('GET', `/products/${id}`)).body.product.rating).toEqual({ average: 4.5, count: 2 });
  });

  it('rejects a rating outside 1 to 5 and a review of an unknown product', async () => {
    app = await startTestApp({ reviews: true });
    const { id } = await app.addProduct();

    expect((await app.call('POST', `/products/${id}/reviews`, { author: 'Ada', rating: 6 })).status).toBe(400);
    expect(
      (await app.call('POST', '/products/00000000-0000-4000-8000-000000000000/reviews', { author: 'Ada', rating: 5 })).status,
    ).toBe(404);
  });

  it('does not exist when off', async () => {
    app = await startTestApp({ reviews: false });
    const { id } = await app.addProduct();

    expect((await app.call('GET', `/products/${id}/reviews`)).status).toBe(404);
    expect((await app.call('GET', `/products/${id}`)).body.product).not.toHaveProperty('rating');
  });
});
