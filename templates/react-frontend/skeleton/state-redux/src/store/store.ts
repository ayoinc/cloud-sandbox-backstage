import { configureStore } from "@reduxjs/toolkit";
import { counterSlice } from "./counterSlice";

/** Creates a store with every slice of the application. */
export function createStore() {
  return configureStore({
    reducer: {
      counter: counterSlice.reducer,
    },
  });
}

export type AppStore = ReturnType<typeof createStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
