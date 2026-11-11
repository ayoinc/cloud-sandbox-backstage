import { describe, expect, it } from "vitest";
import { useCounter } from "../src/store/counter";

describe("counter store", () => {
  it("starts at zero", () => {
    expect(useCounter.getState().count).toBe(0);
  });

  it("increments, decrements and resets", () => {
    useCounter.getState().increment();
    useCounter.getState().increment();
    expect(useCounter.getState().count).toBe(2);

    useCounter.getState().decrement();
    expect(useCounter.getState().count).toBe(1);

    useCounter.getState().reset();
    expect(useCounter.getState().count).toBe(0);
  });
});
