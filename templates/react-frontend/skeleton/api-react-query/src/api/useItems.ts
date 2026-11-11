import { useQuery } from "@tanstack/react-query";
import { listItems } from "./client";
import type { Item } from "./types";

export interface ItemsState {
  items: Item[];
  isLoading: boolean;
  error: Error | null;
}

/** Loads the items with TanStack Query, which caches them under the key `["items"]`. */
export function useItems(): ItemsState {
  const { data, isPending, error } = useQuery({
    queryKey: ["items"],
    queryFn: ({ signal }) => listItems(signal),
  });

  return { items: data ?? [], isLoading: isPending, error };
}
