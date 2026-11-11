import type { Context } from 'hono';
import { GUEST_USER } from './auth';
import { inJsonArray } from './catalog/filter';
import { notAllowedError } from './errors';
import type { AppEnv } from './types';

/**
 * Portal admins: who may change branding and reassign ownership.
 *
 * An admin is a signed-in user named in the optional PORTAL_ADMINS variable,
 * or a row in `branding_admins`. While both are empty the portal has nobody
 * to hand out the role, so the first signed-in user to ask becomes admin.
 * Guests are never admins: guest sign-in is one shared account.
 */

/**
 * PORTAL_ADMINS as lower-case entity refs. Items are comma-separated; a bare
 * name is a user in the default namespace.
 */
export const configuredAdmins = (env: AppEnv['Bindings']): string[] =>
  (env.PORTAL_ADMINS ?? '')
    .split(',')
    .map(item => item.trim().toLowerCase())
    .filter(Boolean)
    .map(item => (item.includes(':') ? item : `user:default/${item}`));

export async function isPortalAdmin(c: Context<AppEnv>): Promise<boolean> {
  const { userEntityRef, ownershipEntityRefs } = c.get('user');
  if (userEntityRef === GUEST_USER) {
    return false;
  }
  // The caller, and any groups their token names.
  const refs = [
    ...new Set(
      [userEntityRef, ...ownershipEntityRefs].map(ref => ref.toLowerCase()),
    ),
  ];
  const configured = configuredAdmins(c.env);
  if (refs.some(ref => configured.includes(ref))) {
    return true;
  }
  const row = await c.env.DB.prepare(
    `SELECT 1 AS found FROM branding_admins WHERE ${inJsonArray(
      'entity_ref',
    )} LIMIT 1`,
  )
    .bind(JSON.stringify(refs))
    .first();
  return row !== null;
}

/**
 * Makes the caller the first admin when there is none yet, and says whether
 * it did. The check and the insert are one statement, so of two people
 * asking at the same moment only one gets the role.
 */
export async function claimFirstAdmin(c: Context<AppEnv>): Promise<boolean> {
  const { userEntityRef } = c.get('user');
  if (userEntityRef === GUEST_USER || configuredAdmins(c.env).length) {
    return false;
  }
  const { meta } = await c.env.DB.prepare(
    "INSERT INTO branding_admins (entity_ref, type, added_by) SELECT ?, 'user', 'first-sign-in' WHERE NOT EXISTS (SELECT 1 FROM branding_admins)",
  )
    .bind(userEntityRef.toLowerCase())
    .run();
  return meta.changes > 0;
}

/** Rejects callers who are not portal admins. Returns the admin's entity ref. */
export async function requirePortalAdmin(c: Context<AppEnv>): Promise<string> {
  if (!(await isPortalAdmin(c))) {
    throw notAllowedError('Admin access required');
  }
  return c.get('user').userEntityRef;
}
