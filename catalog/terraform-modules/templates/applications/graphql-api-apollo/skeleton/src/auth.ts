import { GraphQLError } from 'graphql';
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';
import type { AuthConfig } from './config.js';

/** The caller of a request, taken from a verified token. */
export interface Viewer {
  id: string;
  roles: string[];
}

export type TokenVerifier = (token: string) => Promise<Viewer>;

function toViewer(payload: JWTPayload, rolesClaim: string): Viewer {
  if (!payload.sub) throw new Error('the token has no "sub" claim');
  const roles = payload[rolesClaim];
  return {
    id: payload.sub,
    roles: Array.isArray(roles) ? roles.filter(role => typeof role === 'string') : [],
  };
}

/**
 * Returns the function that checks bearer tokens, or undefined when
 * authentication is off.
 *
 * Provider jwt: HS256 tokens signed with the shared secret JWT_SECRET.
 * Provider oauth2: tokens of an identity provider, checked against the
 * signing keys it publishes (JWKS), its issuer and, when set, the audience.
 */
export function createTokenVerifier(auth: AuthConfig): TokenVerifier | undefined {
  if (!auth.enabled) return undefined;
  const claims = { issuer: auth.issuer, audience: auth.audience };

  if (auth.provider === 'jwt') {
    const secret = new TextEncoder().encode(auth.jwtSecret);
    return async token => {
      const { payload } = await jwtVerify(token, secret, { ...claims, algorithms: ['HS256'] });
      return toViewer(payload, auth.rolesClaim);
    };
  }

  const keys = createRemoteJWKSet(new URL(auth.jwksUri!));
  return async token => {
    const { payload } = await jwtVerify(token, keys, claims);
    return toViewer(payload, auth.rolesClaim);
  };
}

/**
 * Identifies the caller from an Authorization header. A request without a
 * token is anonymous (null); a request with a bad token is rejected.
 */
export async function authenticate(
  verify: TokenVerifier | undefined,
  authorization: unknown,
): Promise<Viewer | null> {
  if (!verify || typeof authorization !== 'string' || authorization === '') return null;
  const [scheme, token] = authorization.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    throw unauthenticated('The Authorization header must be "Bearer <token>".');
  }
  try {
    return await verify(token);
  } catch {
    throw unauthenticated('The token is invalid or has expired.');
  }
}

function unauthenticated(message: string): GraphQLError {
  return new GraphQLError(message, {
    extensions: { code: 'UNAUTHENTICATED', http: { status: 401 } },
  });
}

/**
 * Guards a resolver that changes data. With authentication off it lets
 * everyone through; with it on the caller needs a valid token, and with
 * role-based access control also the given role.
 */
export function authorize(
  auth: Pick<AuthConfig, 'enabled' | 'rbac'>,
  viewer: Viewer | null,
  role: string,
): void {
  if (!auth.enabled) return;
  if (!viewer) throw unauthenticated('You must be signed in to do this.');
  if (auth.rbac && !viewer.roles.includes(role)) {
    throw new GraphQLError(`This needs the "${role}" role.`, {
      extensions: { code: 'FORBIDDEN' },
    });
  }
}
