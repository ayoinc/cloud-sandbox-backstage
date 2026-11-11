import type { UserIdentity } from './auth';

/**
 * Hono environment: Worker bindings, plus the signed-in user and the expiry
 * of the token they presented (seconds since the epoch), set at sign-in.
 */
export interface AppEnv {
  // These are optional, so the generated Env does not list them.
  Bindings: Env & { PORTAL_ADMINS?: string; PORTAL_CONTACT_EMAIL?: string };
  Variables: { user: UserIdentity; tokenExpiresAt: number };
}
