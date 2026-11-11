// Lambda authorizer of the HTTP API (payload format 2.0, simple response).
// API Gateway calls it with the request headers; the request is allowed when
// the x-api-key header carries the key whose SHA-256 hash is in API_KEY_SHA256.
import { createHash, timingSafeEqual } from 'node:crypto';

const expected = Buffer.from(process.env.API_KEY_SHA256 ?? '', 'hex');

export const handler = async (event) => {
  const presented = createHash('sha256')
    .update(event.headers?.['x-api-key'] ?? '')
    .digest();

  return {
    isAuthorized:
      expected.length === presented.length &&
      timingSafeEqual(expected, presented),
  };
};
