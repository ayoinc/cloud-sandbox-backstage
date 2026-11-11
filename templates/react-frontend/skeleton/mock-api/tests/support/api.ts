import { HttpResponse, http } from "msw";
import { afterAll, afterEach, beforeAll } from "vitest";
import type { Item } from "../../src/api/types";
import { apiBaseUrl } from "../../src/config";
import { mockItems } from "../../src/mocks/handlers";
import { server } from "./server";

/** Items the API returns unless a test replaces the response. */
export const defaultItems = mockItems;

/** Starts the mock server for the test file; a request without a handler fails the test. */
export function installApiDouble(): void {
  beforeAll(() => server.listen({ onUnhandledFrame: "error" }));
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
}

/** Makes `GET /items` return `items` for the rest of the current test. */
export function respondWithItems(items: Item[]): void {
  server.use(http.get(`${apiBaseUrl}/items`, () => HttpResponse.json(items)));
}

/** Makes `GET /items` fail with `status` for the rest of the current test. */
export function respondWithStatus(status: number): void {
  server.use(http.get(`${apiBaseUrl}/items`, () => new HttpResponse(null, { status })));
}
