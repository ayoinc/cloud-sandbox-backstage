import axios, { isAxiosError } from "axios";
import { apiBaseUrl } from "../config";
import { ApiError, type Item } from "./types";

/** Axios instance for the backend API. Add interceptors and default headers here. */
export const http = axios.create({
  baseURL: apiBaseUrl,
  headers: { Accept: "application/json" },
});

/** Fetches the items of `GET /items`. */
export async function listItems(signal?: AbortSignal): Promise<Item[]> {
  try {
    const response = await http.get<Item[]>("/items", { signal });
    return response.data;
  } catch (cause) {
    if (isAxiosError(cause) && cause.response) {
      const { status } = cause.response;
      throw new ApiError(`GET /items failed with status ${status}`, status);
    }
    throw cause;
  }
}
