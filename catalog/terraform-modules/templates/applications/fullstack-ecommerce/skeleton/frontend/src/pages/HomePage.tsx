import { type FormEvent, useCallback, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { useCart } from '../cart';
import { useFeatures } from '../features';
import { formatPrice } from '../format';
import { useLoad } from '../useLoad';

export function HomePage() {
  const features = useFeatures();
  const cart = useCart();
  const [draft, setDraft] = useState('');
  const [search, setSearch] = useState('');
  const products = useLoad(useCallback(() => api.listProducts(search), [search]));

  function submitSearch(event: FormEvent) {
    event.preventDefault();
    setSearch(draft.trim());
  }

  return (
    <>
      {features.search && (
        <form className="search" role="search" onSubmit={submitSearch}>
          <input
            type="search"
            aria-label="Search products"
            placeholder="Search products"
            value={draft}
            onChange={event => setDraft(event.target.value)}
          />
          <button type="submit">Search</button>
        </form>
      )}

      {products.error && <p role="alert">{products.error}</p>}
      {products.data?.length === 0 && <p>No products found.</p>}

      <ul className="grid">
        {products.data?.map(product => (
          <li key={product.id} className="card">
            <Link to={`/products/${product.id}`}>
              <h2>{product.name}</h2>
            </Link>
            <p className="price">{formatPrice(product.priceCents)}</p>
            <button type="button" disabled={!product.available} onClick={() => cart.add(product)}>
              {product.available ? 'Add to cart' : 'Out of stock'}
            </button>
          </li>
        ))}
      </ul>
    </>
  );
}
