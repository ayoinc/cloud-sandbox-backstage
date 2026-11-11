import { useCounter } from "../store/counter";
import { Button } from "./Button";

/** Shows the shared counter and the buttons that change it. */
export function Counter() {
  const { count, increment, decrement, reset } = useCounter();

  return (
    <div>
      <p aria-live="polite" style={{ margin: "0 0 0.75rem" }}>
        Count: {count}
      </p>
      <div style={{ display: "flex", gap: "0.5rem" }}>
        <Button onClick={decrement}>Decrease</Button>
        <Button onClick={increment}>Increase</Button>
        <Button variant="secondary" onClick={reset}>
          Reset
        </Button>
      </div>
    </div>
  );
}
