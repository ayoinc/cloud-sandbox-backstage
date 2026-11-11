import { Link, Route, Routes } from 'react-router-dom';
import { api } from './api';
import { CartProvider, useCart } from './cart';
import { FeaturesContext, useFeatures } from './features';
import { AdminPage } from './pages/AdminPage';
import { CartPage } from './pages/CartPage';
import { HomePage } from './pages/HomePage';
import { ProductPage } from './pages/ProductPage';
import { STORE_NAME } from './site';
import { useLoad } from './useLoad';

function Header() {
  const { itemCount } = useCart();
  const features = useFeatures();
  return (
    <header className="header">
      <Link to="/" className="brand">
        {STORE_NAME}
      </Link>
      <nav>
        {(features.productManagement || features.analytics) && <Link to="/admin">Admin</Link>}
        <Link to="/cart">Cart ({itemCount})</Link>
      </nav>
    </header>
  );
}

export function App() {
  const features = useLoad(api.getFeatures);

  if (features.error) return <p role="alert">The store is unavailable: {features.error}</p>;
  if (!features.data) return <p>Loading…</p>;

  return (
    <FeaturesContext.Provider value={features.data}>
      <CartProvider>
        <Header />
        <main>
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/products/:id" element={<ProductPage />} />
            <Route path="/cart" element={<CartPage />} />
            <Route path="/admin" element={<AdminPage />} />
            <Route path="*" element={<p>Page not found.</p>} />
          </Routes>
        </main>
      </CartProvider>
    </FeaturesContext.Provider>
  );
}
