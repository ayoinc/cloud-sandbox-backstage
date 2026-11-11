import { create } from "zustand";

export interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

/**
 * Counter store. Components call `useCounter()` for the whole state or pass a
 * selector, for example `useCounter((state) => state.count)`, to re-render
 * only when that value changes.
 */
export const useCounter = create<CounterState>()((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));
