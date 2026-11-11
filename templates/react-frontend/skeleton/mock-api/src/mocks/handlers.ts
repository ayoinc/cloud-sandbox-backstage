import { HttpResponse, http } from "msw";
import type { Item } from "../api/types";
import { apiBaseUrl } from "../config";

/** Items returned by the mocked `GET /items`. */
export const mockItems: Item[] = [
  { id: "1", name: "First item" },
  { id: "2", name: "Second item" },
  { id: "3", name: "Third item" },
];

/** Request handlers shared by the tests and by the browser worker of the development server. */
export const handlers = [http.get(`${apiBaseUrl}/items`, () => HttpResponse.json(mockItems))];
