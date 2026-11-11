import type { Context, ErrorHandler } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

/** An error that maps to an HTTP status, serialised the way Backstage clients expect. */
export class HttpError extends Error {
  constructor(
    readonly status: ContentfulStatusCode,
    name: string,
    message: string,
  ) {
    super(message);
    this.name = name;
  }
}

export const inputError = (message: string) =>
  new HttpError(400, 'InputError', message);

export const authenticationError = (message: string) =>
  new HttpError(401, 'AuthenticationError', message);

export const notFoundError = (message: string) =>
  new HttpError(404, 'NotFoundError', message);

export const notAllowedError = (message: string) =>
  new HttpError(403, 'NotAllowedError', message);

export const conflictError = (message: string) =>
  new HttpError(409, 'ConflictError', message);

export const notImplementedError = (message: string) =>
  new HttpError(501, 'NotImplementedError', message);

/** The status and text to answer with. Unexpected errors are logged, not shown. */
function describe(error: Error, c: Context) {
  if (error instanceof HttpError) {
    return { status: error.status, name: error.name, message: error.message };
  }
  console.error(
    JSON.stringify({
      message: 'Unhandled error',
      error: error.message,
      stack: error.stack,
      method: c.req.method,
      path: c.req.path,
    }),
  );
  const status: ContentfulStatusCode = 500;
  return { status, name: 'Error', message: 'Unexpected error' };
}

/** Responds in the Backstage error format: `{ error, request, response }`. */
export const handleError: ErrorHandler = (error, c) => {
  const { status, name, message } = describe(error, c);
  return c.json(
    {
      error: { name, message },
      // Backstage reports the path relative to the plugin, without /api/<plugin>.
      request: {
        method: c.req.method,
        url: c.req.path.replace(/^\/api\/[^/]+/, '') || '/',
      },
      response: { statusCode: status },
    },
    status,
  );
};

/**
 * Responds `{ error: "<message>" }`, as the portal's own plugins (branding,
 * ownership) do on the Node backend. Their pages show `error` as text, so
 * the Backstage format would read "[object Object]" there.
 */
export const handlePlainError: ErrorHandler = (error, c) => {
  const { status, message } = describe(error, c);
  return c.json({ error: message }, status);
};
