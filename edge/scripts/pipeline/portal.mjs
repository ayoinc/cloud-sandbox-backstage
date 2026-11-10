// Calls to the portal's pipeline endpoints (/api/pipeline/*).
import { setTimeout as sleep } from 'node:timers/promises';

const RETRY_STATUSES = new Set([408, 429, 500, 502, 503, 504]);
const RETRY_DELAYS_MS = [500, 2000, 5000];

async function failure(response, method, path) {
  const text = await response.text();
  let message = text.slice(0, 500);
  try {
    message = JSON.parse(text).error?.message ?? message;
  } catch {
    // Not a Backstage error body: report the text as it is.
  }
  return Object.assign(
    new Error(
      `Portal answered ${response.status} to ${method} ${path}: ${message}`,
    ),
    { status: response.status },
  );
}

/**
 * Sends one request and returns the parsed JSON answer.
 *
 * `json` is sent as a JSON body; `body` with `contentType` is sent as it is.
 * Pass `retry: true` only for calls that are safe to repeat: a request whose
 * answer was lost may already have been applied. An error made from an answer
 * carries its `status`; an error without one means no answer arrived.
 */
export async function portalRequest(
  portal,
  method,
  path,
  { json, body, contentType, retry = false } = {},
) {
  const delays = retry ? RETRY_DELAYS_MS : [];
  for (let attempt = 0; ; attempt++) {
    let response;
    let error;
    try {
      response = await fetch(`${portal.url}${path}`, {
        method,
        headers: {
          authorization: `Bearer ${portal.token}`,
          ...(json !== undefined && { 'content-type': 'application/json' }),
          ...(contentType && { 'content-type': contentType }),
        },
        body: json === undefined ? body : JSON.stringify(json),
      });
    } catch (cause) {
      error = new Error(
        `Could not reach the portal for ${method} ${path}: ${
          cause.cause?.message ?? cause.message
        }`,
      );
    }
    if (response?.ok) {
      return response.json();
    }
    if (response) {
      error = await failure(response, method, path);
      if (!RETRY_STATUSES.has(response.status)) {
        throw error;
      }
    }
    if (attempt >= delays.length) {
      throw error;
    }
    await sleep(delays[attempt]);
  }
}
