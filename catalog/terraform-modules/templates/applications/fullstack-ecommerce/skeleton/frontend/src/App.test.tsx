import { screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import { STORE_NAME } from './site';
import { lamp, mockApi, mug, renderApp } from './test-helpers';

describe('catalogue', () => {
  it('shows the store name and the products with their prices', async () => {
    mockApi({});
    renderApp();

    expect(await screen.findByRole('heading', { name: 'Mug' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: STORE_NAME })).toBeInTheDocument();
    expect(screen.getByText('$14.00')).toBeInTheDocument();
    expect(screen.getByText('$39.00')).toBeInTheDocument();
  });

  it('says so when the API cannot be reached', async () => {
    mockApi({}, { 'GET /config': undefined });
    renderApp();

    expect(await screen.findByRole('alert')).toHaveTextContent('The store is unavailable');
  });

  it('cannot add a product that is out of stock', async () => {
    mockApi({ inventory: true }, { 'GET /products': { products: [{ ...mug, stock: 0, available: false }] } });
    renderApp();

    expect(await screen.findByRole('button', { name: 'Out of stock' })).toBeDisabled();
  });
});

describe('search', () => {
  it('searches the catalogue when on', async () => {
    const calls = mockApi({ search: true }, { 'GET /products?q=desk%20lamp': { products: [lamp] } });
    renderApp();

    await userEvent.type(await screen.findByRole('searchbox', { name: 'Search products' }), 'desk lamp');
    await userEvent.click(screen.getByRole('button', { name: 'Search' }));

    expect(await screen.findByRole('heading', { name: 'Lamp' })).toBeInTheDocument();
    expect(screen.queryByRole('heading', { name: 'Mug' })).not.toBeInTheDocument();
    expect(calls.map(call => call.path)).toContain('/products?q=desk%20lamp');
  });

  it('has no search box when off', async () => {
    mockApi({ search: false });
    renderApp();

    await screen.findByRole('heading', { name: 'Mug' });
    expect(screen.queryByRole('searchbox')).not.toBeInTheDocument();
  });
});

describe('cart and checkout', () => {
  async function addMugTwiceAndOpenCart() {
    renderApp();
    const card = (await screen.findByRole('heading', { name: 'Mug' })).closest('li')!;
    await userEvent.click(within(card).getByRole('button', { name: 'Add to cart' }));
    await userEvent.click(within(card).getByRole('button', { name: 'Add to cart' }));
    await userEvent.click(screen.getByRole('link', { name: 'Cart (2)' }));
  }

  it('places an order for what is in the cart', async () => {
    const calls = mockApi({}, { 'POST /orders': { order: { id: 'o1', status: 'pending', totalCents: 2800 } } });
    await addMugTwiceAndOpenCart();

    expect(screen.getByText('Total: $28.00')).toBeInTheDocument();
    expect(screen.queryByLabelText(/Card token/)).not.toBeInTheDocument();
    await userEvent.type(screen.getByLabelText('Email'), 'customer@example.com');
    await userEvent.click(screen.getByRole('button', { name: 'Place order' }));

    expect(await screen.findByText('Order o1 over $28.00 is pending.')).toBeInTheDocument();
    expect(calls.find(call => call.method === 'POST')!.body).toEqual({
      customerEmail: 'customer@example.com',
      items: [{ productId: 'p1', quantity: 2 }],
    });
    expect(screen.getByRole('link', { name: 'Cart (0)' })).toBeInTheDocument();
  });

  it('asks for the payment when payments are on', async () => {
    const calls = mockApi({ payments: true }, { 'POST /orders': { order: { id: 'o2', status: 'paid', totalCents: 2800 } } });
    await addMugTwiceAndOpenCart();

    await userEvent.type(screen.getByLabelText('Email'), 'customer@example.com');
    await userEvent.type(screen.getByLabelText(/Card token/), 'tok_visa');
    await userEvent.click(screen.getByRole('button', { name: 'Pay and place order' }));

    expect(await screen.findByText('Order o2 over $28.00 is paid.')).toBeInTheDocument();
    expect(calls.find(call => call.method === 'POST')!.body).toMatchObject({ paymentToken: 'tok_visa' });
  });

  it('keeps the cart across a reload', async () => {
    mockApi({});
    const first = renderApp();
    const card = (await screen.findByRole('heading', { name: 'Mug' })).closest('li')!;
    await userEvent.click(within(card).getByRole('button', { name: 'Add to cart' }));
    first.unmount();

    renderApp();

    expect(await screen.findByRole('link', { name: 'Cart (1)' })).toBeInTheDocument();
  });
});

describe('product page', () => {
  const product = { ...mug, stock: 3, rating: { average: 4.5, count: 2 } };
  const reviews = [{ id: 'r1', author: 'Ada', rating: 5, comment: 'Great mug', createdAt: '2024-01-01T00:00:00.000Z' }];

  it('shows stock, rating and reviews, and takes a new review', async () => {
    const calls = mockApi(
      { reviews: true, inventory: true },
      {
        'GET /products/p1': { product },
        'GET /products/p1/reviews': { reviews },
        'POST /products/p1/reviews': { review: reviews[0] },
      },
    );
    renderApp('/products/p1');

    expect(await screen.findByText('Rated 4.5 out of 5 (2)')).toBeInTheDocument();
    expect(screen.getByText('3 in stock')).toBeInTheDocument();
    expect(await screen.findByText('Great mug')).toBeInTheDocument();

    await userEvent.type(screen.getByLabelText('Your name'), 'Grace');
    await userEvent.selectOptions(screen.getByLabelText('Rating'), '4');
    await userEvent.click(screen.getByRole('button', { name: 'Submit review' }));

    expect(calls.find(call => call.method === 'POST')!.body).toEqual({ author: 'Grace', rating: 4, comment: '' });
  });

  it('has no reviews and no stock level when those are off', async () => {
    mockApi({}, { 'GET /products/p1': { product: mug } });
    renderApp('/products/p1');

    expect(await screen.findByRole('heading', { name: 'Mug' })).toBeInTheDocument();
    expect(screen.queryByRole('heading', { name: 'Reviews' })).not.toBeInTheDocument();
    expect(screen.queryByText(/in stock/)).not.toBeInTheDocument();
  });
});

describe('admin', () => {
  const summary = { orders: 2, revenueCents: 4000, averageOrderCents: 2000, topProducts: [{ name: 'Mug', unitsSold: 3 }] };

  async function signIn() {
    await userEvent.type(await screen.findByLabelText(/Admin token/), 'secret');
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));
  }

  it('shows the sales figures when analytics is on', async () => {
    const calls = mockApi({ analytics: true }, { 'GET /admin/analytics/summary': { summary } });
    renderApp('/admin');
    await signIn();

    expect(await screen.findByText('$40.00')).toBeInTheDocument();
    expect(screen.getByText('Mug: 3 sold')).toBeInTheDocument();
    expect(screen.queryByRole('heading', { name: 'Products' })).not.toBeInTheDocument();
    expect(calls.find(call => call.path === '/admin/analytics/summary')!.authorization).toBe('Bearer secret');
  });

  it('adds and deletes products when product management is on', async () => {
    const calls = mockApi(
      { productManagement: true },
      { 'POST /admin/products': { product: lamp }, 'DELETE /admin/products/p1': {} },
    );
    renderApp('/admin');
    await signIn();

    await userEvent.type(await screen.findByLabelText('Name'), 'Pen');
    await userEvent.type(screen.getByLabelText('Price'), '2.50');
    await userEvent.click(screen.getByRole('button', { name: 'Add product' }));
    await userEvent.click(await screen.findByRole('button', { name: 'Delete Mug' }));

    expect(calls.find(call => call.method === 'POST')).toMatchObject({
      body: { name: 'Pen', description: '', priceCents: 250, stock: 0 },
      authorization: 'Bearer secret',
    });
    expect(calls.some(call => call.method === 'DELETE' && call.path === '/admin/products/p1')).toBe(true);
    expect(screen.queryByRole('heading', { name: 'Sales' })).not.toBeInTheDocument();
  });

  it('is not linked or reachable when both admin features are off', async () => {
    mockApi({});
    renderApp('/admin');

    expect(await screen.findByText('Page not found.')).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Admin' })).not.toBeInTheDocument();
  });
});
