import type { Context } from 'hono';
import { HttpError, inputError } from './errors';
import type { AppEnv } from './types';

const decoder = new TextDecoder();

export const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

/**
 * Reads a JSON request body of at most `maxBytes`. The size is checked
 * before parsing, because the body ends up in a D1 statement and D1 limits
 * how large one bound value may be. A body that declares a larger size is
 * refused without being read.
 */
export async function readJson(
  c: Context<AppEnv>,
  maxBytes: number,
): Promise<unknown> {
  const declared = Number(c.req.header('content-length') ?? 0);
  const bytes = declared > maxBytes ? undefined : await c.req.arrayBuffer();
  if (!bytes || bytes.byteLength > maxBytes) {
    throw new HttpError(
      413,
      'PayloadTooLargeError',
      `Request body is ${
        bytes?.byteLength ?? declared
      } bytes, the limit is ${maxBytes}`,
    );
  }
  try {
    return JSON.parse(decoder.decode(bytes));
  } catch {
    throw inputError('Request body is not valid JSON');
  }
}

/** Sends JSON that is already serialised, such as rows stored as JSON text. */
export const rawJson = (
  body: string | ReadableStream,
  headers?: Record<string, string>,
) =>
  new Response(body, {
    headers: { 'content-type': 'application/json; charset=utf-8', ...headers },
  });
