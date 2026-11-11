import { Hono, type Context } from 'hono';
import { getCookie, setCookie } from 'hono/cookie';
import { checkToken, GUEST_USER, signToken } from './auth';
import { conflictError, inputError, notFoundError } from './errors';
import type { AppEnv } from './types';

/**
 * Linked sign-in methods (`/api/account-links`). A person who can sign in
 * both with GitHub and with Google links the second to the account they
 * use, and from then on either signs them in as that one account, with its
 * organisation, look, files and settings.
 *
 * Linking happens in the provider's window, as a sign-in does. Before it
 * opens, the app asks here for a link intent: a short-lived, signed,
 * HttpOnly cookie naming the account to link to, readable only by that
 * provider's sign-in handler. Nothing the browser sends in the window
 * itself can name another account, so nobody can link their sign-in to
 * someone else's account.
 */

export const LINK_PROVIDERS = ['github', 'google'];
const LINK_AUDIENCE = 'cloud-sandbox-account-link';
const LINK_TTL_SECONDS = 600;

const linkCookie = (provider: string) => `${provider}-link`;
const handlerPath = (provider: string) => `/api/auth/${provider}/handler`;

/** The account a link intent for `provider` names, if this browser holds one. */
export async function linkIntent(
  c: Context<AppEnv>,
  provider: string,
): Promise<string | undefined> {
  const token = getCookie(c, linkCookie(provider));
  if (!token) {
    return undefined;
  }
  // Used once, whatever happens next.
  setCookie(c, linkCookie(provider), '', {
    path: handlerPath(provider),
    maxAge: 0,
  });
  const checked = await checkToken(c.env.SESSION_SECRET, LINK_AUDIENCE, token);
  return 'problem' in checked ? undefined : String(checked.claims.sub);
}

/**
 * Links the account `id` at `provider`, which on its own is `ownRef`, to
 * the account `userRef`. Refused when that would hide something: an
 * account that already has an organisation or registered files of its own
 * keeps signing in as itself.
 */
export async function linkAccount(
  db: D1Database,
  provider: string,
  id: string,
  ownRef: string,
  userRef: string,
): Promise<void> {
  const key = id.toLowerCase();
  if (ownRef.toLowerCase() === userRef) {
    throw inputError('That is the account you are signed in with already');
  }
  const [existing, membership, files] = await db.batch<Record<string, unknown>>(
    [
      db
        .prepare(
          'SELECT user_ref FROM account_links WHERE provider = ? AND id = ?',
        )
        .bind(provider, key),
      db
        .prepare('SELECT 1 FROM organisation_members WHERE user_ref = ?')
        .bind(ownRef.toLowerCase()),
      db
        .prepare(
          'SELECT 1 FROM locations WHERE account = ? AND removed_at IS NULL LIMIT 1',
        )
        .bind(ownRef.toLowerCase()),
    ],
  );
  const linkedTo = existing.results[0]?.user_ref;
  if (linkedTo === userRef) {
    return;
  }
  if (linkedTo) {
    throw conflictError(
      `That ${provider} account is already linked to another account`,
    );
  }
  if (membership.results.length || files.results.length) {
    throw conflictError(
      `That ${provider} account has an organisation or registered files of its own. Leave the organisation and unregister the files with it first, or keep signing in with it on its own`,
    );
  }
  await db
    .prepare(
      'INSERT INTO account_links (provider, id, user_ref, linked_at) VALUES (?, ?, ?, ?)',
    )
    .bind(provider, key, userRef, new Date().toISOString())
    .run();
}

export const accountLinkRoutes = new Hono<AppEnv>();

const caller = (c: Context<AppEnv>) =>
  c.get('user').userEntityRef.toLowerCase();

const requireProvider = (provider: string) => {
  if (!LINK_PROVIDERS.includes(provider)) {
    throw notFoundError(`Unknown sign-in method '${provider}'`);
  }
  return provider;
};

// The sign-in methods linked to the caller's account.
accountLinkRoutes.get('/', async c => {
  const { results } = await c.env.DB.prepare(
    'SELECT provider, id, linked_at FROM account_links WHERE user_ref = ? ORDER BY linked_at',
  )
    .bind(caller(c))
    .all<{ provider: string; id: string; linked_at: string }>();
  return c.json({
    userEntityRef: caller(c),
    links: results.map(row => ({
      provider: row.provider,
      id: row.id,
      linkedAt: row.linked_at,
    })),
  });
});

// Allows the next sign-in with `provider` in this browser, within ten
// minutes, to link that account to the caller's.
accountLinkRoutes.post('/:provider/intent', async c => {
  const provider = requireProvider(c.req.param('provider'));
  const userRef = caller(c);
  if (userRef === GUEST_USER) {
    throw inputError(
      'The guest account is shared, so nothing can be linked to it. Sign in with your own account',
    );
  }
  setCookie(
    c,
    linkCookie(provider),
    await signToken(c.env.SESSION_SECRET, LINK_AUDIENCE, LINK_TTL_SECONDS, {
      sub: userRef,
    }),
    {
      httpOnly: true,
      secure: new URL(c.req.url).protocol === 'https:',
      sameSite: 'Lax',
      path: handlerPath(provider),
      maxAge: LINK_TTL_SECONDS,
    },
  );
  return c.body(null, 204);
});

// Unlinks a sign-in method from the caller's account. It signs in as its
// own account again from the next refresh.
accountLinkRoutes.delete('/:provider/:id', async c => {
  const provider = requireProvider(c.req.param('provider'));
  const { meta } = await c.env.DB.prepare(
    'DELETE FROM account_links WHERE provider = ? AND id = ? AND user_ref = ?',
  )
    .bind(provider, c.req.param('id').toLowerCase(), caller(c))
    .run();
  if (!meta.changes) {
    throw notFoundError('No such linked sign-in method');
  }
  return c.body(null, 204);
});
