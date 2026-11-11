import { type AxiosAdapter, AxiosError } from "axios";
import { afterEach, beforeEach } from "vitest";
import { http } from "../../src/api/client";
import type { Item } from "../../src/api/types";
import { apiBaseUrl } from "../../src/config";

/** Items the API returns unless a test replaces the response. */
export const defaultItems: Item[] = [
  { id: "1", name: "First item" },
  { id: "2", name: "Second item" },
];

const networkAdapter = http.defaults.adapter;

/** Builds an Axios adapter that answers only `GET /items` of the API, with `status` and `data`. */
function adapterFor(status: number, data: unknown): AxiosAdapter {
  return async (config) => {
    const matches = config.baseURL === apiBaseUrl && config.url === "/items";
    const response = {
      data: matches ? data : null,
      status: matches ? status : 404,
      statusText: "",
      headers: {},
      config,
    };
    if (response.status >= 400) {
      throw new AxiosError(
        `Request failed with status code ${response.status}`,
        AxiosError.ERR_BAD_RESPONSE,
        config,
        null,
        response,
      );
    }
    return response;
  };
}

/** Answers API requests in every test without touching the network. */
export function installApiDouble(): void {
  beforeEach(() => respondWithItems(defaultItems));
  afterEach(() => {
    http.defaults.adapter = networkAdapter;
  });
}

/** Makes `GET /items` return `items` for the rest of the current test. */
export function respondWithItems(items: Item[]): void {
  http.defaults.adapter = adapterFor(200, items);
}

/** Makes `GET /items` fail with `status` for the rest of the current test. */
export function respondWithStatus(status: number): void {
  http.defaults.adapter = adapterFor(status, null);
}
