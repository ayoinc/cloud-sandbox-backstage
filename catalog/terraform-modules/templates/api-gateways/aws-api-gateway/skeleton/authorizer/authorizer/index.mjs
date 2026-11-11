// Lambda authorizer (type TOKEN) of the API. It accepts a bearer token when
// the token is a JWT signed by a key of the issuer's JSON Web Key Set, was
// issued by JWT_ISSUER for JWT_AUDIENCE and is inside its validity period.
// Uses only Node.js built-ins.
import { createPublicKey, verify as verifySignature } from 'node:crypto';

// JWS algorithm -> digest and signature options for node:crypto.
const ALGORITHMS = {
  RS256: { digest: 'sha256' },
  RS384: { digest: 'sha384' },
  RS512: { digest: 'sha512' },
  ES256: { digest: 'sha256', dsaEncoding: 'ieee-p1363' },
  ES384: { digest: 'sha384', dsaEncoding: 'ieee-p1363' },
};

const KEY_CACHE_MS = 10 * 60 * 1000;
const KEY_REFRESH_INTERVAL_MS = 60 * 1000;
const CLOCK_SKEW_SECONDS = 60;

const decodeJson = part =>
  JSON.parse(Buffer.from(part, 'base64url').toString('utf8'));

const withoutTrailingSlash = url => String(url ?? '').replace(/\/+$/, '');

// Signing keys of the issuer by key id, refreshed after KEY_CACHE_MS or when
// a token names a key that is not in the cache. Unknown key ids trigger at
// most one fetch per KEY_REFRESH_INTERVAL_MS, so forged tokens cannot be used
// to flood the issuer.
export function createKeySource(jwksUri, fetchImpl = fetch, clock = Date.now) {
  let keys = new Map();
  let fetchedAt = 0;

  const refresh = async () => {
    const response = await fetchImpl(jwksUri);
    if (!response.ok) {
      throw new Error(`The key set answered ${response.status}`);
    }
    const body = await response.json();
    keys = new Map(
      (body.keys ?? []).filter(key => key.kid).map(key => [key.kid, key]),
    );
    fetchedAt = clock();
  };

  return async kid => {
    const age = clock() - fetchedAt;
    if (age > KEY_CACHE_MS || (!keys.has(kid) && age > KEY_REFRESH_INTERVAL_MS)) {
      await refresh();
    }
    return keys.get(kid);
  };
}

// Returns the claims of a valid token, throws otherwise.
export async function verifyToken(token, { issuer, audience, getKey, now }) {
  const parts = String(token).split('.');
  if (parts.length !== 3) {
    throw new Error('Not a JWT');
  }
  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const header = decodeJson(encodedHeader);
  const claims = decodeJson(encodedPayload);

  const algorithm = ALGORITHMS[header.alg];
  if (!algorithm) {
    throw new Error(`Unsupported algorithm ${header.alg}`);
  }
  const jwk = await getKey(header.kid);
  if (!jwk) {
    throw new Error(`Unknown signing key ${header.kid}`);
  }
  const valid = verifySignature(
    algorithm.digest,
    Buffer.from(`${encodedHeader}.${encodedPayload}`),
    {
      key: createPublicKey({ key: jwk, format: 'jwk' }),
      dsaEncoding: algorithm.dsaEncoding,
    },
    Buffer.from(encodedSignature, 'base64url'),
  );
  if (!valid) {
    throw new Error('Invalid signature');
  }

  const seconds = Math.floor((now ?? Date.now()) / 1000);
  if (withoutTrailingSlash(claims.iss) !== withoutTrailingSlash(issuer)) {
    throw new Error('Wrong issuer');
  }
  const audiences = [claims.aud].flat();
  if (!audiences.includes(audience)) {
    throw new Error('Wrong audience');
  }
  if (typeof claims.exp !== 'number' || claims.exp + CLOCK_SKEW_SECONDS < seconds) {
    throw new Error('Token expired');
  }
  if (typeof claims.nbf === 'number' && claims.nbf - CLOCK_SKEW_SECONDS > seconds) {
    throw new Error('Token not valid yet');
  }
  return claims;
}

// IAM policy that lets the caller invoke every method of the stage. It covers
// the whole stage because API Gateway caches the policy per token.
export function allowPolicy(principalId, methodArn, claims) {
  const [apiArn, stage] = methodArn.split('/');
  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: 'Allow',
          Resource: `${apiArn}/${stage}/*/*`,
        },
      ],
    },
    // Available to the function as event.requestContext.authorizer.
    context: {
      sub: String(claims.sub ?? ''),
      scope: String(claims.scope ?? ''),
    },
  };
}

export function createHandler({ issuer, audience, getKey }) {
  return async event => {
    const token = String(event.authorizationToken ?? '').replace(/^Bearer /i, '');
    try {
      const claims = await verifyToken(token, { issuer, audience, getKey });
      return allowPolicy(claims.sub ?? 'user', event.methodArn, claims);
    } catch (error) {
      console.warn(`Token rejected: ${error.message}`);
      // API Gateway answers 401 for exactly this error message.
      throw new Error('Unauthorized');
    }
  };
}

export const handler = createHandler({
  issuer: process.env.JWT_ISSUER,
  audience: process.env.JWT_AUDIENCE,
  getKey: createKeySource(process.env.JWKS_URI),
});
