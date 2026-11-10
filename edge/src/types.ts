import type { UserIdentity } from './auth';

/**
 * Hono environment: Worker bindings, plus the signed-in user and the expiry
 * of the token they presented (seconds since the epoch), set at sign-in.
 */
export interface AppEnv {
  Bindings: Env;
  Variables: { user: UserIdentity; tokenExpiresAt: number };
}
