import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { migrate } from '../src/db/index.js';
import { CREATE_PRODUCT, startTestServer, type TestServer } from './helpers.js';

const widget = { name: 'Widget', description: 'A small part', priceCents: 1250 };

describe('products', () => {
  let server: TestServer;
  beforeEach(async () => {
    server = await startTestServer();
  });
  afterEach(() => server.close());

  it('creates a product and reads it back', async () => {
    const created = await server.query(CREATE_PRODUCT, { variables: { input: widget } });

    expect(created.body.errors).toBeUndefined();
    const product = created.body.data!.createProduct;
    expect(product).toMatchObject({ ...widget, inStock: true });
    expect(Date.parse(product.createdAt)).not.toBeNaN();

    const read = await server.query('query ($id: ID!) { product(id: $id) { id name priceCents inStock } }', {
      variables: { id: product.id },
    });
    expect(read.body.data!.product).toEqual({ id: product.id, name: 'Widget', priceCents: 1250, inStock: true });
  });

  it('lists products newest first, a page at a time', async () => {
    for (const name of ['first', 'second', 'third']) {
      await server.query(CREATE_PRODUCT, { variables: { input: { name, priceCents: 100 } } });
      // Creation times have millisecond precision.
      await new Promise(resolve => setTimeout(resolve, 5));
    }

    const page = await server.query('{ products(limit: 2) { name } }');
    expect(page.body.data!.products).toEqual([{ name: 'third' }, { name: 'second' }]);

    const rest = await server.query('{ products(limit: 2, offset: 2) { name } }');
    expect(rest.body.data!.products).toEqual([{ name: 'first' }]);
  });

  it('answers null for a product that does not exist', async () => {
    const result = await server.query('{ product(id: "missing") { id } }');

    expect(result.body).toEqual({ data: { product: null } });
  });

  it('deletes a product', async () => {
    const created = await server.query(CREATE_PRODUCT, { variables: { input: widget } });
    const { id } = created.body.data!.createProduct;
    const remove = 'mutation ($id: ID!) { deleteProduct(id: $id) }';

    expect((await server.query(remove, { variables: { id } })).body.data).toEqual({ deleteProduct: true });
    expect((await server.query(remove, { variables: { id } })).body.data).toEqual({ deleteProduct: false });
  });

  it('rejects invalid input', async () => {
    const emptyName = await server.query(CREATE_PRODUCT, { variables: { input: { name: ' ', priceCents: 1 } } });
    expect(emptyName.body.errors![0]!.extensions!.code).toBe('BAD_USER_INPUT');

    const hugePage = await server.query('{ products(limit: 500) { id } }');
    expect(hugePage.body.errors![0]!.extensions!.code).toBe('BAD_USER_INPUT');
  });

  it('can migrate a database that is already up to date', async () => {
    await expect(migrate(server.db)).resolves.toBeUndefined();
  });
});
