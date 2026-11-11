// Helpers shared by every endpoint: responses, request parsing and routing
// of API Gateway proxy events.

const JSON_HEADERS = { 'Content-Type': 'application/json' };

export const json = (statusCode, body) => ({
  statusCode,
  headers: JSON_HEADERS,
  body: JSON.stringify(body),
});

export const noContent = () => ({ statusCode: 204, headers: {}, body: '' });

// Thrown by a handler to answer with a specific status and message.
export class HttpError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

// The request body as an object. Anything else is a client error.
export function parseObject(event) {
  const raw = event.isBase64Encoded
    ? Buffer.from(event.body ?? '', 'base64').toString('utf8')
    : event.body;
  let value;
  try {
    value = JSON.parse(raw ?? '');
  } catch {
    value = undefined;
  }
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'The request body must be a JSON object');
  }
  return value;
}

// Stub of an endpoint that is routed but has no implementation yet.
export const notImplemented = event =>
  json(501, {
    message: `${event.httpMethod} ${event.resource} is not implemented`,
  });

// Calls the handler registered for "<METHOD> <resource path>".
export async function route(routes, event) {
  const handler = routes[`${event.httpMethod} ${event.resource}`];
  if (!handler) {
    return json(404, { message: 'Not found' });
  }
  try {
    return await handler(event);
  } catch (error) {
    if (error instanceof HttpError) {
      return json(error.statusCode, { message: error.message });
    }
    console.error(error);
    return json(500, { message: 'Internal server error' });
  }
}
