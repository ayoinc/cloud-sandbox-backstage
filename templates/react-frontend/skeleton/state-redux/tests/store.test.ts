import { describe, expect, it } from "vitest";
import { decrement, increment, reset } from "../src/store/counterSlice";
import { createStore } from "../src/store/store";

describe("counter slice", () => {
  it("starts at zero", () => {
    expect(createStore().getState().counter.value).toBe(0);
  });

  it("increments, decrements and resets", () => {
    const store = createStore();

    store.dispatch(increment());
    store.dispatch(increment());
    expect(store.getState().counter.value).toBe(2);

    store.dispatch(decrement());
    expect(store.getState().counter.value).toBe(1);

    store.dispatch(reset());
    expect(store.getState().counter.value).toBe(0);
  });

  it("gives every store its own state", () => {
    const first = createStore();
    first.dispatch(increment());

    expect(createStore().getState().counter.value).toBe(0);
  });
});
