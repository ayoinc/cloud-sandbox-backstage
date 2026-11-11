import { useDispatch, useSelector } from "react-redux";
import { decrement, increment, reset } from "./counterSlice";
import type { AppDispatch, RootState } from "./store";

const useAppDispatch = useDispatch.withTypes<AppDispatch>();
const useAppSelector = useSelector.withTypes<RootState>();

/** Counter value and the actions that change it. */
export function useCounter() {
  const count = useAppSelector((state) => state.counter.value);
  const dispatch = useAppDispatch();

  return {
    count,
    increment: () => dispatch(increment()),
    decrement: () => dispatch(decrement()),
    reset: () => dispatch(reset()),
  };
}
