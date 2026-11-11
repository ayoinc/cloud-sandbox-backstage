import { type FormEvent, useCallback, useState } from 'react';
import { api } from '../api';
import { useFeatures } from '../features';
import { formatPrice } from '../format';
import { useLoad } from '../useLoad';

const TOKEN_KEY = 'adminToken';

function ProductManagement({ adminToken }: { adminToken: string }) {
  const products = useLoad(useCallback(() => api.listProducts(), []));
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [stock, setStock] = useState('0');
  const [error, setError] = useState('');

  async function run(change: () => Promise<unknown>) {
    setError('');
    try {
      await change();
      products.reload();
    } catch (failure) {
      setError((failure as Error).message);
    }
  }

  function create(event: FormEvent) {
    event.preventDefault();
    void run(async () => {
      const product = { name, description, priceCents: Math.round(Number(price) * 100), stock: Number(stock) };
      await api.createProduct(product, adminToken);
      setName('');
      setDescription('');
      setPrice('');
    });
  }

  return (
    <section>
      <h2>Products</h2>
      {error && <p role="alert">{error}</p>}
      <table>
        <tbody>
          {products.data?.map(product => (
            <tr key={product.id}>
              <td>{product.name}</td>
              <td>{formatPrice(product.priceCents)}</td>
              <td>
                <button type="button" onClick={() => void run(() => api.deleteProduct(product.id, adminToken))}>
                  Delete {product.name}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <form className="stack" onSubmit={create}>
        <h3>Add a product</h3>
        <label>
          Name
          <input required value={name} onChange={event => setName(event.target.value)} />
        </label>
        <label>
          Description
          <textarea value={description} onChange={event => setDescription(event.target.value)} />
        </label>
        <label>
          Price
          <input type="number" required min={0} step="0.01" value={price} onChange={event => setPrice(event.target.value)} />
        </label>
        <label>
          Stock
          <input type="number" required min={0} value={stock} onChange={event => setStock(event.target.value)} />
        </label>
        <button type="submit">Add product</button>
      </form>
    </section>
  );
}

function Analytics({ adminToken }: { adminToken: string }) {
  const summary = useLoad(useCallback(() => api.getSalesSummary(adminToken), [adminToken]));

  if (summary.error) return <p role="alert">{summary.error}</p>;
  if (!summary.data) return <p>Loading…</p>;
  const { orders, revenueCents, averageOrderCents, topProducts } = summary.data;

  return (
    <section>
      <h2>Sales</h2>
      <dl className="figures">
        <dt>Orders</dt>
        <dd>{orders}</dd>
        <dt>Revenue</dt>
        <dd>{formatPrice(revenueCents)}</dd>
        <dt>Average order</dt>
        <dd>{formatPrice(averageOrderCents)}</dd>
      </dl>
      <h3>Best sellers</h3>
      {topProducts.length === 0 && <p>No sales yet.</p>}
      <ol>
        {topProducts.map(product => (
          <li key={product.name}>
            {product.name}: {product.unitsSold} sold
          </li>
        ))}
      </ol>
    </section>
  );
}

export function AdminPage() {
  const features = useFeatures();
  const [adminToken, setAdminToken] = useState(() => sessionStorage.getItem(TOKEN_KEY) ?? '');
  const [draft, setDraft] = useState('');

  function signIn(event: FormEvent) {
    event.preventDefault();
    sessionStorage.setItem(TOKEN_KEY, draft);
    setAdminToken(draft);
  }

  if (!features.productManagement && !features.analytics) return <p>Page not found.</p>;

  if (!adminToken) {
    return (
      <form className="stack" onSubmit={signIn}>
        <h1>Admin</h1>
        <label>
          Admin token
          <input type="password" required value={draft} onChange={event => setDraft(event.target.value)} />
          <small>The value of ADMIN_TOKEN of the API.</small>
        </label>
        <button type="submit">Sign in</button>
      </form>
    );
  }

  return (
    <>
      <h1>Admin</h1>
      {features.analytics && <Analytics adminToken={adminToken} />}
      {features.productManagement && <ProductManagement adminToken={adminToken} />}
    </>
  );
}
