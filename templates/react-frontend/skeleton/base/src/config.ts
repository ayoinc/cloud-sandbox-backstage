import app from "./app.json";

/**
 * Base URL of the backend API, without a trailing slash. `VITE_API_BASE_URL`
 * replaces the default from `app.json` when the bundle is built.
 */
export const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || app.apiBaseUrl).replace(/\/+$/, "");
