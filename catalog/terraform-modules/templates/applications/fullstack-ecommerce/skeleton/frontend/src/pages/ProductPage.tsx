import { type FormEvent, useCallback, useState } from 'react';
import { useParams } from 'react-router-dom';
import { api } from '../api';
import { useCart } from '../cart';
import { useFeatures } from '../features';
import { formatPrice } from '../format';
import { useLoad } from '../useLoad';

function Reviews({ productId, onAdded }: { productId: string; onAdded(): void }) {
  const reviews = useLoad(useCallback(() => api.listReviews(productId), [productId]));
  const [author, setAuthor] = useState('');
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');
  const [error, setError] = useState('');

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError('');
    try {
      await api.addReview(productId, { author, rating, comment });
      setAuthor('');
      setComment('');
      reviews.reload();
      onAdded();
    } catch (failure) {
      setError((failure as Error).message);
    }
  }

  return (
    <section>
      <h2>Reviews</h2>
      {reviews.data?.length === 0 && <p>No reviews yet.</p>}
      <ul className="reviews">
        {reviews.data?.map(review => (
          <li key={review.id}>
            <strong>{review.author}</strong> rated it {review.rating} out of 5
            {review.comment && <p>{review.comment}</p>}
          </li>
        ))}
      </ul>

      <form className="stack" onSubmit={submit}>
        <h3>Write a review</h3>
        <label>
          Your name
          <input required value={author} onChange={event => setAuthor(event.target.value)} />
        </label>
        <label>
          Rating
          <select value={rating} onChange={event => setRating(Number(event.target.value))}>
            {[5, 4, 3, 2, 1].map(value => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </label>
        <label>
          Comment
          <textarea value={comment} onChange={event => setComment(event.target.value)} />
        </label>
        {error && <p role="alert">{error}</p>}
        <button type="submit">Submit review</button>
      </form>
    </section>
  );
}

export function ProductPage() {
  const { id = '' } = useParams();
  const features = useFeatures();
  const cart = useCart();
  const product = useLoad(useCallback(() => api.getProduct(id), [id]));

  if (product.error) return <p role="alert">{product.error}</p>;
  if (!product.data) return <p>Loading…</p>;
  const { name, description, priceCents, available, stock, rating } = product.data;

  return (
    <article>
      <h1>{name}</h1>
      <p>{description}</p>
      <p className="price">{formatPrice(priceCents)}</p>
      {rating && (
        <p>{rating.average === null ? 'Not rated yet' : `Rated ${rating.average} out of 5 (${rating.count})`}</p>
      )}
      {features.inventory && <p>{available ? `${stock} in stock` : 'Out of stock'}</p>}
      <button type="button" disabled={!available} onClick={() => cart.add(product.data!)}>
        Add to cart
      </button>

      {features.reviews && <Reviews productId={id} onAdded={product.reload} />}
    </article>
  );
}
