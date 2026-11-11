import { afterEach, beforeEach, vi } from "vitest";
import type { Item } from "../../src/api/types";
import { apiBaseUrl } from "../../src/config";

/** Items the API returns unless a test replaces the response. */
export const defaultItems: Item[] = [
  { id: "1", name: "First item" },
  { id: "2", name: "Second item" },
];

/** Replaces `fetch` so that only `GET /items` of the API is answered, with `createResponse`. */
function stubFetch(createResponse: () => Response): void {
  vi.stubGlobal(
    "fetch",
    vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      return url === `${apiBaseUrl}/items` ? createResponse() : new Response(null, { status: 404 });
    }),
  );
}

/** Answers API requests in every test without touching the network. */
export function installApiDouble(): void {
  beforeEach(() => respondWithItems(defaultItems));
  afterEach(() => vi.unstubAllGlobals());
}

/** Makes `GET /items` return `items` for the rest of the current test. */
export function respondWithItems(items: Item[]): void {
  stubFetch(() => Response.json(items));
}

/** Makes `GET /items` fail with `status` for the rest of the current test. */
export function respondWithStatus(status: number): void {
  stubFetch(() => new Response(null, { status }));
}
