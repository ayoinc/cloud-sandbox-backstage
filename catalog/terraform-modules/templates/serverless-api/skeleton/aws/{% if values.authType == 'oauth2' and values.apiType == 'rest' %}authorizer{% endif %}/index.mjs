// Lambda authorizer of the REST API (TOKEN type).
// It verifies the bearer token of a request against the signing keys that the
// OpenID Connect issuer publishes, and checks the issuer, audience and validity
// period. OIDC_ISSUER and OIDC_AUDIENCE come from the Terraform variables
// oauth2_issuer and oauth2_audience.
import { createPublicKey, verify } from 'node:crypto';

const issuer = process.env.OIDC_ISSUER;
const audience = process.env.OIDC_AUDIENCE;

// Signature algorithms accepted in the token header.
const algorithms = {
  RS256: { hash: 'sha256', keyType: 'RSA' },
  RS384: { hash: 'sha384', keyType: 'RSA' },
  RS512: { hash: 'sha512', keyType: 'RSA' },
  ES256: { hash: 'sha256', keyType: 'EC', curve: 'P-256' },
  ES384: { hash: 'sha384', keyType: 'EC', curve: 'P-384' },
};

const clockSkewSeconds = 60;
const keyRefreshIntervalMs = 5 * 60 * 1000;

let signingKeys = new Map();
let signingKeysLoadedAt = 0;

async function getJson(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(5000) });
  if (!response.ok) {
    throw new Error(`GET ${url} returned ${response.status}`);
  }
  return response.json();
}

async function loadSigningKeys() {
  const discovery = await getJson(
    `${issuer.replace(/\/$/, '')}/.well-known/openid-configuration`,
  );
  const { keys } = await getJson(discovery.jwks_uri);
  signingKeys = new Map(
    keys.filter((key) => key.kid && key.use !== 'enc').map((key) => [key.kid, key]),
  );
  signingKeysLoadedAt = Date.now();
}

// Returns the key with the given id. The key set is read again when the id is
// unknown (the issuer may have rotated its keys), at most once per interval.
async function signingKey(keyId) {
  if (
    !signingKeys.has(keyId) &&
    Date.now() - signingKeysLoadedAt > keyRefreshIntervalMs
  ) {
    await loadSigningKeys();
  }
  return signingKeys.get(keyId);
}

function decodePart(part) {
  return JSON.parse(Buffer.from(part, 'base64url').toString('utf8'));
}

async function verifyToken(token) {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('not a signed JWT');
  }
  const [encodedHeader, encodedClaims, encodedSignature] = parts;

  const header = decodePart(encodedHeader);
  const algorithm = Object.hasOwn(algorithms, header.alg)
    ? algorithms[header.alg]
    : undefined;
  if (!algorithm) {
    throw new Error(`algorithm ${JSON.stringify(header.alg)} is not accepted`);
  }

  const jwk = await signingKey(header.kid);
  if (!jwk) {
    throw new Error(
      `signing key ${JSON.stringify(header.kid)} is not published by the issuer`,
    );
  }
  if (
    jwk.kty !== algorithm.keyType ||
    (algorithm.curve && jwk.crv !== algorithm.curve) ||
    (jwk.alg && jwk.alg !== header.alg)
  ) {
    throw new Error('signing key does not match the token algorithm');
  }

  const signatureIsValid = verify(
    algorithm.hash,
    Buffer.from(`${encodedHeader}.${encodedClaims}`),
    { key: createPublicKey({ key: jwk, format: 'jwk' }), dsaEncoding: 'ieee-p1363' },
    Buffer.from(encodedSignature, 'base64url'),
  );
  if (!signatureIsValid) {
    throw new Error('signature is not valid');
  }

  const claims = decodePart(encodedClaims);
  const now = Math.floor(Date.now() / 1000);
  if (claims.iss !== issuer) {
    throw new Error('issuer does not match');
  }
  if (![claims.aud].flat().includes(audience)) {
    throw new Error('audience does not match');
  }
  if (typeof claims.exp !== 'number' || claims.exp + clockSkewSeconds <= now) {
    throw new Error('token has expired');
  }
  if (typeof claims.nbf === 'number' && claims.nbf - clockSkewSeconds > now) {
    throw new Error('token is not valid yet');
  }
  return claims;
}

export const handler = async (event) => {
  const token = (event.authorizationToken ?? '').replace(/^Bearer\s+/i, '');

  let claims;
  try {
    claims = await verifyToken(token);
  } catch (error) {
    console.warn(`Token rejected: ${error.message}`);
    // API Gateway answers 401 when the authorizer fails with this message.
    throw new Error('Unauthorized');
  }

  // methodArn is arn:aws:execute-api:<region>:<account>:<api>/<stage>/<method>/<path>.
  // The policy covers the whole stage because API Gateway caches it per token.
  const [api, stage] = event.methodArn.split('/');
  return {
    principalId: String(claims.sub ?? claims.client_id ?? 'unknown'),
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Effect: 'Allow',
          Action: 'execute-api:Invoke',
          Resource: `${api}/${stage}/*`,
        },
      ],
    },
    context: {
      scope: String(claims.scope ?? claims.scp ?? ''),
    },
  };
};
