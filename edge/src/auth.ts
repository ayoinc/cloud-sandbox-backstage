import { Hono, type Context, type MiddlewareHandler } from 'hono';
import { setCookie } from 'hono/cookie';
import { recordSignIn } from './catalog/users';
import { base64ToBytes, bytesToBase64 } from './encoding';
import { authenticationError, notFoundError } from './errors';
import type { AppEnv } from './types';

/**
 * Backstage user tokens, sign-in sessions and guest sign-in.
 *
 * Tokens are HS256 JWTs signed with the SESSION_SECRET Worker secret. User
 * tokens carry the same claims as Backstage user tokens, so the front end
 * reads the expiry from them the way it does with the Node backend.
 */

export interface UserIdentity {
  userEntityRef: string;
  ownershipEntityRefs: string[];
}

export interface Profile {
  email?: string;
  displayName?: string;
  picture?: string;
}

/** A sign-in, kept in the browser as a signed, HttpOnly cookie. */
export interface Session {
  provider: string;
  /** What the provider's allow-list matches: a GitHub login or a Google email. */
  id: string;
  sub: string;
  profile: Profile;
}

export const SESSION_AUDIENCE = 'cloud-sandbox-session';
export const SESSION_TTL_SECONDS = 7 * 24 * 3600;
export const PORTAL_SESSION = { name: 'portal-session', path: '/api/auth' };
export const GUEST_PROVIDER = 'guest';

const USER_TOKEN_TTL_SECONDS = 3600;
const USER_TOKEN_AUDIENCE = 'backstage';
export const GUEST_USER = 'user:development/guest';

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const base64Url = (bytes: Uint8Array) =>
  bytesToBase64(bytes)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replace(/=+$/, '');

const fromBase64Url = (value: string) =>
  base64ToBytes(value.replaceAll('-', '+').replaceAll('_', '/'));

const signingKey = (secret: string) =>
  crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );

/** Signs claims as a JWT for one audience, expiring after `ttlSeconds`. */
export async function signToken(
  secret: string,
  audience: string,
  ttlSeconds: number,
  claims: Record<string, unknown>,
  type = 'JWT',
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = [
    { typ: type, alg: 'HS256' },
    { ...claims, aud: audience, iat: now, exp: now + ttlSeconds },
  ]
    .map(part => base64Url(encoder.encode(JSON.stringify(part))))
    .join('.');
  const signature = await crypto.subtle.sign(
    'HMAC',
    await signingKey(secret),
    encoder.encode(unsigned),
  );
  return `${unsigned}.${base64Url(new Uint8Array(signature))}`;
}

/** The claims of a token, or what is wrong with it: "the token <problem>". */
export type TokenCheck =
  | { claims: Record<string, unknown> }
  | { problem: string };

/**
 * Checks the signature, audience and expiry of a token signed here for
 * `audience`, and says which of them does not hold.
 */
export async function checkToken(
  secret: string,
  audience: string,
  token: string,
): Promise<TokenCheck> {
  const [header, claims, signature, ...rest] = token.split('.');
  if (!header || !claims || !signature || rest.length) {
    return { problem: 'is not a signed token' };
  }
  try {
    const valid = await crypto.subtle.verify(
      'HMAC',
      await signingKey(secret),
      fromBase64Url(signature),
      encoder.encode(`${header}.${claims}`),
    );
    if (!valid) {
      return {
        problem:
          'has a signature that does not match (SESSION_SECRET changed, or the token was altered)',
      };
    }
    const { alg } = JSON.parse(decoder.decode(fromBase64Url(header)));
    const payload = JSON.parse(decoder.decode(fromBase64Url(claims)));
    if (alg !== 'HS256') {
      return { problem: 'is signed with an algorithm that is not accepted' };
    }
    if (payload.aud !== audience) {
      return { problem: 'was issued for another purpose' };
    }
    if (typeof payload.exp !== 'number') {
      return { problem: 'has no expiry' };
    }
    if (payload.exp <= Date.now() / 1000) {
      return {
        problem: `expired at ${new Date(payload.exp * 1000).toISOString()}`,
      };
    }
    return { claims: payload };
  } catch {
    return { problem: 'cannot be decoded' };
  }
}

/**
 * Returns the claims of a token signed here for `audience`, or `undefined`
 * if the signature, audience or expiry does not hold.
 */
export async function verifyToken(
  secret: string,
  audience: string,
  token: string,
): Promise<Record<string, unknown> | undefined> {
  const checked = await checkToken(secret, audience, token);
  return 'claims' in checked ? checked.claims : undefined;
}

/** The `backstageIdentity` part of a sign-in response for one user. */
export async function backstageIdentity(
  secret: string,
  requestUrl: string,
  userEntityRef: string,
) {
  const identity: UserIdentity = {
    userEntityRef,
    ownershipEntityRefs: [userEntityRef],
  };
  return {
    token: await signToken(
      secret,
      USER_TOKEN_AUDIENCE,
      USER_TOKEN_TTL_SECONDS,
      {
        iss: `${new URL(requestUrl).origin}/api/auth`,
        sub: userEntityRef,
        ent: identity.ownershipEntityRefs,
      },
      'vnd.backstage.user',
    ),
    identity: { type: 'user', ...identity },
    expiresInSeconds: USER_TOKEN_TTL_SECONDS,
  };
}

/**
 * Signs the request in from its `Authorization` header, or rejects it.
 * `schemes` are the header schemes accepted, in lower case.
 */
export async function signInFromHeader(
  c: Context<AppEnv>,
  schemes: string[] = ['bearer'],
): Promise<void> {
  const [scheme, token] = (c.req.header('authorization') ?? '').split(' ');
  if (!token || !schemes.includes(scheme.toLowerCase())) {
    throw authenticationError('Missing credentials');
  }
  const claims = await verifyToken(
    c.env.SESSION_SECRET,
    USER_TOKEN_AUDIENCE,
    token,
  );
  if (typeof claims?.sub !== 'string') {
    throw authenticationError('Invalid or expired token');
  }
  c.set('user', {
    userEntityRef: claims.sub,
    ownershipEntityRefs: Array.isArray(claims.ent)
      ? claims.ent.map(String)
      : [claims.sub],
  });
  c.set('tokenExpiresAt', Number(claims.exp));
}

/** Whether `token` is a user token this portal issued and has not expired. */
export async function isUserToken(env: Env, token: string): Promise<boolean> {
  const claims = await verifyToken(
    env.SESSION_SECRET,
    USER_TOKEN_AUDIENCE,
    token,
  );
  return typeof claims?.sub === 'string';
}

/** Rejects requests without a valid `Authorization: Bearer` user token. */
export const requireUser: MiddlewareHandler<AppEnv> = async (c, next) => {
  await signInFromHeader(c);
  await next();
};

/**
 * Puts a session token where `/api/auth/github/refresh` can read it. Session
 * cookies are scoped to their own provider's routes, but the GitHub Actions
 * tab asks the GitHub provider for credentials whichever way the user signed
 * in, so sign-ins that are not GitHub's leave a copy on the shared auth path.
 */
export function sharePortalSession(
  c: Context<AppEnv>,
  sessionToken: string,
  maxAge: number,
) {
  setCookie(c, PORTAL_SESSION.name, sessionToken, {
    httpOnly: true,
    secure: new URL(c.req.url).protocol === 'https:',
    sameSite: 'Lax',
    path: PORTAL_SESSION.path,
    maxAge,
  });
}

export const guestRoutes = new Hono<AppEnv>();

guestRoutes.get('/refresh', async c => {
  if (c.env.GUEST_AUTH_ENABLED !== 'true') {
    throw notFoundError('Guest sign-in is not enabled');
  }
  // Browsers cannot set this header across origins without a CORS preflight.
  if (c.req.header('x-requested-with') !== 'XMLHttpRequest') {
    throw authenticationError('Invalid X-Requested-With header');
  }
  const session: Session = {
    provider: GUEST_PROVIDER,
    id: 'guest',
    sub: GUEST_USER,
    profile: {},
  };
  await recordSignIn(c.env.DB, session);
  sharePortalSession(
    c,
    await signToken(
      c.env.SESSION_SECRET,
      SESSION_AUDIENCE,
      SESSION_TTL_SECONDS,
      { ...session },
    ),
    SESSION_TTL_SECONDS,
  );
  return c.json({
    profile: {},
    backstageIdentity: await backstageIdentity(
      c.env.SESSION_SECRET,
      c.req.url,
      GUEST_USER,
    ),
  });
});
