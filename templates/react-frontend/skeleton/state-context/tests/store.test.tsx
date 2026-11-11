import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { CounterProvider, counterReducer, useCounter } from "../src/store/counter";

describe("counterReducer", () => {
  it("increments, decrements and resets", () => {
    expect(counterReducer(1, { type: "increment" })).toBe(2);
    expect(counterReducer(1, { type: "decrement" })).toBe(0);
    expect(counterReducer(5, { type: "reset" })).toBe(0);
  });
});

describe("useCounter", () => {
  it("shares the count of the surrounding CounterProvider", () => {
    const { result } = renderHook(() => useCounter(), { wrapper: CounterProvider });

    act(() => result.current.increment());
    act(() => result.current.increment());
    expect(result.current.count).toBe(2);

    act(() => result.current.reset());
    expect(result.current.count).toBe(0);
  });

  it("fails outside a CounterProvider", () => {
    expect(() => renderHook(() => useCounter())).toThrow(
      "useCounter must be used inside a CounterProvider",
    );
  });
});
