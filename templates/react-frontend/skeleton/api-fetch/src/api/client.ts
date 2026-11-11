import { apiBaseUrl } from "../config";
import { ApiError, type Item } from "./types";

async function getJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    headers: { Accept: "application/json" },
    signal,
  });
  if (!response.ok) {
    throw new ApiError(`GET ${path} failed with status ${response.status}`, response.status);
  }
  return (await response.json()) as T;
}

/** Fetches the items of `GET /items`. */
export function listItems(signal?: AbortSignal): Promise<Item[]> {
  return getJson<Item[]>("/items", signal);
}
