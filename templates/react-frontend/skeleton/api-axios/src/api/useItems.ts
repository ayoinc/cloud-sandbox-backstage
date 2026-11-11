import { useEffect, useState } from "react";
import { listItems } from "./client";
import type { Item } from "./types";

export interface ItemsState {
  items: Item[];
  isLoading: boolean;
  error: Error | null;
}

/** Loads the items when the component mounts and cancels the request when it unmounts. */
export function useItems(): ItemsState {
  const [state, setState] = useState<ItemsState>({ items: [], isLoading: true, error: null });

  useEffect(() => {
    const controller = new AbortController();

    listItems(controller.signal)
      .then((items) => {
        if (!controller.signal.aborted) {
          setState({ items, isLoading: false, error: null });
        }
      })
      .catch((cause: unknown) => {
        if (!controller.signal.aborted) {
          const error = cause instanceof Error ? cause : new Error(String(cause));
          setState({ items: [], isLoading: false, error });
        }
      });

    return () => controller.abort();
  }, []);

  return state;
}
