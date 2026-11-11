import { type FormEvent, useState } from 'react';
import { api, type Order } from '../api';
import { useCart } from '../cart';
import { useFeatures } from '../features';
import { formatPrice } from '../format';

export function CartPage() {
  const features = useFeatures();
  const cart = useCart();
  const [customerEmail, setCustomerEmail] = useState('');
  const [paymentToken, setPaymentToken] = useState('');
  const [error, setError] = useState('');
  const [order, setOrder] = useState<Order>();

  async function checkout(event: FormEvent) {
    event.preventDefault();
    setError('');
    try {
      const placed = await api.placeOrder({
        customerEmail,
        items: cart.lines.map(line => ({ productId: line.productId, quantity: line.quantity })),
        paymentToken: features.payments ? paymentToken : undefined,
      });
      cart.clear();
      setOrder(placed);
    } catch (failure) {
      setError((failure as Error).message);
    }
  }

  if (order) {
    return (
      <section>
        <h1>Thank you for your order</h1>
        <p>
          Order {order.id} over {formatPrice(order.totalCents)} is {order.status}.
        </p>
      </section>
    );
  }

  if (cart.lines.length === 0) return <p>Your cart is empty.</p>;

  return (
    <section>
      <h1>Your cart</h1>
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Price</th>
            <th>Quantity</th>
          </tr>
        </thead>
        <tbody>
          {cart.lines.map(line => (
            <tr key={line.productId}>
              <td>{line.name}</td>
              <td>{formatPrice(line.priceCents)}</td>
              <td>
                <input
                  type="number"
                  min={0}
                  aria-label={`Quantity of ${line.name}`}
                  value={line.quantity}
                  onChange={event => cart.setQuantity(line.productId, Number(event.target.value))}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="price">Total: {formatPrice(cart.totalCents)}</p>

      <form className="stack" onSubmit={checkout}>
        <h2>Checkout</h2>
        <label>
          Email
          <input type="email" required value={customerEmail} onChange={event => setCustomerEmail(event.target.value)} />
        </label>
        {features.payments && (
          <label>
            Card token
            <input required value={paymentToken} onChange={event => setPaymentToken(event.target.value)} />
            <small>The sandbox payment provider accepts any token except tok_declined.</small>
          </label>
        )}
        {error && <p role="alert">{error}</p>}
        <button type="submit">{features.payments ? 'Pay and place order' : 'Place order'}</button>
      </form>
    </section>
  );
}
