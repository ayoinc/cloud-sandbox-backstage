import type { ErrorHandler } from 'hono';
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

/** Responds in the Backstage error format: `{ error, request, response }`. */
export const handleError: ErrorHandler = (error, c) => {
  const known = error instanceof HttpError;
  const status = known ? error.status : 500;
  if (!known) {
    console.error(
      JSON.stringify({
        message: 'Unhandled error',
        error: error.message,
        stack: error.stack,
        method: c.req.method,
        path: c.req.path,
      }),
    );
  }
  return c.json(
    {
      error: {
        name: known ? error.name : 'Error',
        message: known ? error.message : 'Unexpected error',
      },
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
