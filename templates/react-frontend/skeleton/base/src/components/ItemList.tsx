import { useItems } from "../api/useItems";

/** Lists the items returned by `GET /items`, with loading, error and empty states. */
export function ItemList() {
  const { items, isLoading, error } = useItems();

  if (isLoading) {
    return <p role="status">Loading items...</p>;
  }
  if (error) {
    return <p role="alert">Could not load items: {error.message}</p>;
  }
  if (items.length === 0) {
    return <p>No items yet.</p>;
  }
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
}
