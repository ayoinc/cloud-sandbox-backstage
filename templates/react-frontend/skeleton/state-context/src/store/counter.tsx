import { createContext, type ReactNode, useContext, useMemo, useReducer } from "react";

export type CounterAction = { type: "increment" } | { type: "decrement" } | { type: "reset" };

/** Computes the next count for an action. */
export function counterReducer(count: number, action: CounterAction): number {
  switch (action.type) {
    case "increment":
      return count + 1;
    case "decrement":
      return count - 1;
    case "reset":
      return 0;
  }
}

export interface CounterValue {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

const CounterContext = createContext<CounterValue | null>(null);

/** Holds the counter state for the components below it. */
export function CounterProvider({ children }: { children: ReactNode }) {
  const [count, dispatch] = useReducer(counterReducer, 0);
  const value = useMemo<CounterValue>(
    () => ({
      count,
      increment: () => dispatch({ type: "increment" }),
      decrement: () => dispatch({ type: "decrement" }),
      reset: () => dispatch({ type: "reset" }),
    }),
    [count],
  );

  return <CounterContext.Provider value={value}>{children}</CounterContext.Provider>;
}

/** Counter value and the actions that change it. */
export function useCounter(): CounterValue {
  const value = useContext(CounterContext);
  if (!value) {
    throw new Error("useCounter must be used inside a CounterProvider");
  }
  return value;
}
