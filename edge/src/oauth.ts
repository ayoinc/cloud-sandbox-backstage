import { Hono, type Context } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import {
  backstageIdentity,
  checkToken,
  GUEST_PROVIDER,
  PORTAL_SESSION,
  SESSION_AUDIENCE,
  SESSION_TTL_SECONDS,
  sharePortalSession,
  signToken,
  type Profile,
  type Session,
} from './auth';
import { recordSignIn } from './catalog/users';
import { bytesToBase64, decodeJson, encodeJson } from './encoding';
import {
  authenticationError,
  HttpError,
  inputError,
  notAllowedError,
  notFoundError,
} from './errors';
import { isRecord } from './json';
import type { AppEnv } from './types';

/**
 * GitHub and Google sign-in, speaking the Backstage auth protocol the front
 * end expects: `/start` opens the provider in a popup, `/handler/frame`
 * posts the result back to the app, `/refresh` restores a session and
 * `/logout` ends it.
 *
 * The provider is only asked who the user is. No provider token is kept or
 * sent to the browser: the session is a signed, HttpOnly cookie, and the
 * allow-list is checked again every time a session is refreshed. Where the
 * front end expects an access token for GitHub's API it is given the user's
 * own portal token, which only `/api/github` on this Worker accepts.
 *
 * Everyone who signs in is recorded as a catalog User entity, with the name,
 * email and picture the provider gave: see `catalog/users.ts`.
 */

interface Account {
  /** What the allow-list matches: a GitHub login or a Google email. */
  id: string;
  userEntityRef: string;
  profile: Profile;
}

interface Provider {
  credentials(env: Env): { clientId: string; clientSecret: string };
  authorizeUrl: string;
  /** Scopes asked of the provider, whatever the front end requests. */
  scope: string;
  /** Exchanges the one-time code for the signed-in account. */
  account(env: Env, code: string, redirectUri: string): Promise<Account>;
  isAllowed(env: Env, id: string): boolean;
  /**
   * True when the front end also asks this provider for an API access
   * token. The GitHub Actions tab does, whichever way the user signed in.
   */
  issuesAccessToken: boolean;
}

// Each provider keeps its own session cookie (`github-session`,
// `google-session`), so connecting a second provider does not replace the
// first one's session.
const NONCE_TTL_SECONDS = 600;

// The scope the front end asks for when it wants GitHub API credentials.
// Signing in never asks for it.
const API_SCOPE = 'repo';

const list = (value: string) =>
  value
    .split(',')
    .map(item => item.trim().toLowerCase())
    .filter(Boolean);

/** Catalog entity names allow letters, digits and `-_.` only. */
const entityName = (value: string) =>
  value.toLowerCase().replace(/[^a-z0-9_.-]/g, '-');

async function postForm(
  url: string,
  fields: Record<string, string>,
): Promise<Record<string, unknown>> {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(fields),
  });
  const body = await response.json<Record<string, unknown>>();
  if (!response.ok || body.error) {
    throw authenticationError(
      `Sign-in was rejected by the provider: ${[
        body.error ?? response.status,
        body.error_description,
      ]
        .filter(Boolean)
        .join(', ')}`,
    );
  }
  return body;
}

const github: Provider = {
  credentials: env => ({
    clientId: env.GITHUB_CLIENT_ID,
    clientSecret: env.GITHUB_CLIENT_SECRET,
  }),
  authorizeUrl: 'https://github.com/login/oauth/authorize',
  scope: '',
  async account(env, code, redirectUri) {
    const token = await postForm(
      'https://github.com/login/oauth/access_token',
      {
        client_id: env.GITHUB_CLIENT_ID,
        client_secret: env.GITHUB_CLIENT_SECRET,
        code,
        redirect_uri: redirectUri,
      },
    );
    const response = await fetch('https://api.github.com/user', {
      headers: {
        accept: 'application/vnd.github+json',
        authorization: `Bearer ${token.access_token}`,
        'user-agent': 'cloud-sandbox-portal',
      },
    });
    if (!response.ok) {
      throw authenticationError('Could not read the GitHub user');
    }
    const user = await response.json<{
      login: string;
      name?: string | null;
      email?: string | null;
      avatar_url?: string;
    }>();
    return {
      id: user.login.toLowerCase(),
      userEntityRef: `user:default/${entityName(user.login)}`,
      profile: {
        email: user.email ?? undefined,
        displayName: user.name ?? user.login,
        picture: user.avatar_url,
      },
    };
  },
  isAllowed: (env, id) => list(env.GITHUB_ALLOWED_USERS).includes(id),
  issuesAccessToken: true,
};

const google: Provider = {
  credentials: env => ({
    clientId: env.GOOGLE_CLIENT_ID,
    clientSecret: env.GOOGLE_CLIENT_SECRET,
  }),
  authorizeUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
  scope: 'openid email profile',
  async account(env, code, redirectUri) {
    const token = await postForm('https://oauth2.googleapis.com/token', {
      client_id: env.GOOGLE_CLIENT_ID,
      client_secret: env.GOOGLE_CLIENT_SECRET,
      code,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    });
    // The ID token came straight from Google over TLS in exchange for our
    // client secret, so its claims are trusted without checking the signature.
    const claims = decodeJson(
      String(token.id_token)
        .split('.')[1]
        ?.replaceAll('-', '+')
        .replaceAll('_', '/') ?? '',
    ) as
      | {
          email?: string;
          email_verified?: boolean;
          name?: string;
          picture?: string;
        }
      | undefined;
    if (!claims?.email || claims.email_verified !== true) {
      throw authenticationError('Google did not return a verified email');
    }
    const email = claims.email.toLowerCase();
    return {
      id: email,
      userEntityRef: `user:default/${entityName(email.split('@')[0])}`,
      profile: {
        email,
        displayName: claims.name ?? email,
        picture: claims.picture,
      },
    };
  },
  isAllowed: (env, id) =>
    list(env.GOOGLE_ALLOWED_EMAILS).includes(id) ||
    list(env.GOOGLE_ALLOWED_DOMAINS).includes(id.split('@')[1] ?? ''),
  issuesAccessToken: false,
};

const providers: Record<string, Provider> = { github, google };

/** Provider ids that have a client configured, for the sign-in page. */
export const configuredProviders = (env: Env) =>
  Object.entries(providers)
    .filter(([, provider]) => provider.credentials(env).clientId)
    .map(([id]) => id);

type AuthContext = Context<AppEnv, '/:provider/*'>;

function resolve(c: AuthContext) {
  const id = c.req.param('provider');
  const provider = providers[id];
  if (!provider) {
    throw notFoundError(`Unknown auth provider '${id}'`);
  }
  const { clientId, clientSecret } = provider.credentials(c.env);
  if (!clientId || !clientSecret) {
    throw notFoundError(`Sign-in with ${id} is not configured`);
  }
  const url = new URL(c.req.url);
  return {
    id,
    provider,
    clientId,
    origin: url.origin,
    secure: url.protocol === 'https:',
    base: `/api/auth/${id}`,
    redirectUri: `${url.origin}/api/auth/${id}/handler/frame`,
  };
}

function requireXhr(c: AuthContext) {
  // Browsers cannot set this header across origins without a CORS preflight.
  if (c.req.header('x-requested-with') !== 'XMLHttpRequest') {
    throw authenticationError('Invalid X-Requested-With header');
  }
}

/** The page shown in the popup: hands the result to the app and closes. */
async function popupResponse(c: AuthContext, origin: string, message: unknown) {
  const encode = (value: string) =>
    encodeURIComponent(value).replace(/'/g, '%27');
  const script = `
    var authResponse = decodeURIComponent('${encode(JSON.stringify(message))}');
    var origin = decodeURIComponent('${encode(origin)}');
    (window.opener || window.parent).postMessage({'type': 'config_info', 'targetOrigin': origin}, '*');
    (window.opener || window.parent).postMessage(JSON.parse(authResponse), origin);
    setTimeout(() => { window.close(); }, 100);
  `;
  const hash = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(script),
  );
  return c.html(`<html><body><script>${script}</script></body></html>`, 200, {
    'x-frame-options': 'sameorigin',
    'content-security-policy': `script-src 'sha256-${bytesToBase64(
      new Uint8Array(hash),
    )}'`,
  });
}

/** Why the sign-in behind a session would not be accepted now, if it would not. */
function whyNotAllowed(env: Env, session: Session): string | undefined {
  if (session.provider === GUEST_PROVIDER) {
    return env.GUEST_AUTH_ENABLED === 'true'
      ? undefined
      : 'guest sign-in is not enabled';
  }
  const provider = providers[session.provider];
  if (!provider) {
    return `there is no sign-in method called ${session.provider}`;
  }
  const { clientId, clientSecret } = provider.credentials(env);
  if (!clientId || !clientSecret) {
    return `sign-in with ${session.provider} is not configured`;
  }
  return provider.isAllowed(env, session.id)
    ? undefined
    : `${session.id} is not on the ${session.provider} allow-list`;
}

/**
 * The session a cookie holds, or `refused`: why there is none to use.
 * `sent` tells a cookie that was refused from one the browser did not send.
 */
type SessionCookie =
  | { token: string; session: Session & { exp: number } }
  | { refused: string; sent: boolean };

async function readSession(
  c: AuthContext,
  cookieName: string,
): Promise<SessionCookie> {
  const token = getCookie(c, cookieName);
  if (!token) {
    return { refused: `no ${cookieName} cookie was sent`, sent: false };
  }
  const checked = await checkToken(
    c.env.SESSION_SECRET,
    SESSION_AUDIENCE,
    token,
  );
  if ('problem' in checked) {
    return {
      refused: `the ${cookieName} cookie ${checked.problem}`,
      sent: true,
    };
  }
  const { provider, id, sub, profile, exp } = checked.claims;
  // The allow-list is checked against these, so a session that lacks one
  // cannot be accepted. A missing profile only costs the display name.
  if (
    typeof provider !== 'string' ||
    typeof id !== 'string' ||
    typeof sub !== 'string'
  ) {
    return {
      refused: `the ${cookieName} cookie holds a session without a provider, id or sub`,
      sent: true,
    };
  }
  return {
    token,
    session: {
      provider,
      id,
      sub,
      profile: isRecord(profile) ? (profile as Profile) : {},
      exp: Number(exp),
    },
  };
}

/**
 * The response to a sign-in or a refresh. `signsIn` is false when the
 * session belongs to another sign-in method and the caller only wants API
 * credentials: the response then carries no identity, so the front end
 * cannot take it for a sign-in with this provider.
 */
async function sessionResponse(
  c: AuthContext,
  provider: Provider,
  session: Session,
  scope: string,
  signsIn: boolean,
) {
  const identity = await backstageIdentity(
    c.env.SESSION_SECRET,
    c.req.url,
    session.sub,
  );
  return {
    profile: session.profile,
    // The front end treats the scopes it asked for as granted.
    providerInfo: provider.issuesAccessToken
      ? {
          scope,
          accessToken: identity.token,
          expiresInSeconds: identity.expiresInSeconds,
        }
      : { scope },
    ...(signsIn && { backstageIdentity: identity }),
  };
}

export const oauthRoutes = new Hono<AppEnv>();

oauthRoutes.get('/:provider/start', c => {
  const { provider, clientId, origin, secure, base, redirectUri } = resolve(c);
  if (!c.req.query('env')) {
    throw inputError('No env provided in request query parameters');
  }
  // The app and this API share an origin; nothing else may start a sign-in.
  if (new URL(c.req.query('origin') ?? origin).origin !== origin) {
    throw notAllowedError('Origin is not allowed');
  }
  if ((c.req.query('flow') ?? 'popup') !== 'popup') {
    throw inputError('Only the popup sign-in flow is supported');
  }
  const nonce = crypto.randomUUID();
  setCookie(c, `${c.req.param('provider')}-nonce`, nonce, {
    httpOnly: true,
    secure,
    sameSite: 'Lax',
    path: `${base}/handler`,
    maxAge: NONCE_TTL_SECONDS,
  });
  const authorize = new URL(provider.authorizeUrl);
  authorize.search = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    ...(provider.scope && { scope: provider.scope }),
    state: encodeJson({ nonce, scope: c.req.query('scope') ?? '' }),
  }).toString();
  return c.redirect(authorize.toString());
});

oauthRoutes.get('/:provider/handler/frame', async c => {
  const { id, provider, origin, secure, base, redirectUri } = resolve(c);
  try {
    const state = decodeJson(c.req.query('state') ?? '') as
      | { nonce?: string; scope?: string }
      | undefined;
    const nonce = getCookie(c, `${id}-nonce`);
    if (!nonce || !state?.nonce || nonce !== state.nonce) {
      throw notAllowedError('Invalid nonce');
    }
    const code = c.req.query('code');
    if (!code) {
      throw authenticationError(
        c.req.query('error_description') ?? 'Sign-in was cancelled',
      );
    }
    const account = await provider.account(c.env, code, redirectUri);
    if (!provider.isAllowed(c.env, account.id)) {
      throw notAllowedError(
        `${account.id} is not allowed to sign in to this portal`,
      );
    }
    const session: Session = {
      provider: id,
      id: account.id,
      sub: account.userEntityRef,
      profile: account.profile,
    };
    await recordSignIn(c.env.DB, session);
    const sessionToken = await signToken(
      c.env.SESSION_SECRET,
      SESSION_AUDIENCE,
      SESSION_TTL_SECONDS,
      { ...session },
    );
    setCookie(c, `${id}-session`, sessionToken, {
      httpOnly: true,
      secure,
      sameSite: 'Lax',
      path: base,
      maxAge: SESSION_TTL_SECONDS,
    });
    if (!provider.issuesAccessToken) {
      sharePortalSession(c, sessionToken, SESSION_TTL_SECONDS);
    }
    return await popupResponse(c, origin, {
      type: 'authorization_response',
      response: await sessionResponse(
        c,
        provider,
        session,
        state.scope ?? '',
        true,
      ),
    });
  } catch (error) {
    const known = error instanceof HttpError;
    if (!known) {
      console.error(
        JSON.stringify({
          message: 'Sign-in failed',
          provider: id,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
    }
    return popupResponse(c, origin, {
      type: 'authorization_response',
      error: {
        name: known ? error.name : 'Error',
        message: known ? error.message : 'Sign-in failed',
      },
    });
  }
});

oauthRoutes.get('/:provider/refresh', async c => {
  requireXhr(c);
  const id = c.req.param('provider');
  const provider = providers[id];
  const scope = c.req.query('scope') ?? '';
  // Why each session that was looked at could not be used: the 401 and the
  // log both carry it, so a session that ends early can be explained.
  const refused: string[] = [];
  // Whether a cookie the browser did send was turned down. A visitor who
  // has not signed in sends none, on every page load.
  let turnedDown = false;
  const own = await readSession(c, `${id}-session`);
  if ('refused' in own) {
    refused.push(own.refused);
    turnedDown ||= own.sent;
  } else if (provider) {
    const problem =
      own.session.provider === id
        ? whyNotAllowed(c.env, own.session)
        : `the ${id}-session cookie holds a ${own.session.provider} session`;
    if (!problem) {
      await recordSignIn(c.env.DB, own.session);
      if (!provider.issuesAccessToken) {
        sharePortalSession(
          c,
          own.token,
          own.session.exp - Math.floor(Date.now() / 1000),
        );
      }
      return c.json(
        await sessionResponse(c, provider, own.session, scope, true),
      );
    }
    refused.push(problem);
    turnedDown = true;
  }
  // API credentials for a user who signed in another way: a guest or a
  // Google user opening the GitHub Actions tab. They get a token for the
  // identity they already have, and only if that sign-in still stands.
  if (
    provider?.issuesAccessToken &&
    scope.split(/[\s,]+/).includes(API_SCOPE)
  ) {
    const other = await readSession(c, PORTAL_SESSION.name);
    if ('refused' in other) {
      refused.push(other.refused);
      turnedDown ||= other.sent;
    } else {
      const problem =
        other.session.provider === id
          ? `the ${PORTAL_SESSION.name} cookie holds a ${id} session`
          : whyNotAllowed(c.env, other.session);
      if (!problem) {
        return c.json(
          await sessionResponse(c, provider, other.session, scope, false),
        );
      }
      refused.push(problem);
      turnedDown = true;
    }
  }
  // Answers 404 for a provider that is unknown or not configured.
  resolve(c);
  const entry = JSON.stringify({
    message: 'Session refresh refused',
    provider: id,
    reasons: refused,
    // Names only: shows which cookies reached the Worker.
    cookies: Object.keys(getCookie(c)),
  });
  if (turnedDown) {
    console.warn(entry);
  } else {
    console.log(entry);
  }
  throw authenticationError(`No session to refresh: ${refused.join('; ')}`);
});

oauthRoutes.post('/:provider/logout', async c => {
  const { id, provider, base } = resolve(c);
  requireXhr(c);
  // Logged so that a session ended by a sign-out, the front end's idle
  // timeout included, can be told from one that a refresh refused.
  const ended = await readSession(c, `${id}-session`);
  console.log(
    JSON.stringify({
      message: 'Signed out',
      provider: id,
      user: 'session' in ended ? ended.session.sub : undefined,
    }),
  );
  deleteCookie(c, `${id}-session`, { path: base });
  if (!provider.issuesAccessToken) {
    deleteCookie(c, PORTAL_SESSION.name, { path: PORTAL_SESSION.path });
  }
  return c.body(null, 200);
});
