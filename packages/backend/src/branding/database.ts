/**
 * =============================================================================
 * Portal Admins Database Operations
 * =============================================================================
 *
 * Database access layer for portal admin management. The plugin once held
 * the portal-wide branding too; that now belongs to organisations, and the
 * old branding tables are left as they are, unused.
 *
 * =============================================================================
 */

import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import { GUEST_USER } from '../organisations/rules';

/**
 * Initialize the portal admins table
 */
export async function initializeTables(
  knex: Knex,
  logger: LoggerService,
): Promise<void> {
  // Create branding_admins table if not exists
  const hasAdminsTable = await knex.schema.hasTable('branding_admins');
  if (!hasAdminsTable) {
    logger.info('Creating branding_admins table');
    await knex.schema.createTable('branding_admins', table => {
      table.increments('id').primary();
      table.string('entity_ref').notNullable().unique();
      table.string('type').notNullable();
      table.timestamp('added_at').defaultTo(knex.fn.now());
      table.string('added_by').nullable();
    });
  }
}

/**
 * The administrators named in PORTAL_ADMINS, the same setting as on the
 * Cloudflare deployment. Each item is a full entity ref, or a bare name
 * meaning user:default/<name>.
 */
export function configuredAdmins(): string[] {
  return (process.env.PORTAL_ADMINS ?? '')
    .split(',')
    .map(item => item.trim().toLowerCase())
    .filter(Boolean)
    .map(item => (item.includes(':') ? item : `user:default/${item}`));
}

/**
 * Makes the first person to sign in the administrator, as the Cloudflare
 * deployment does: only while no administrator is configured or recorded,
 * and never a guest. Returns whether this user was made one.
 */
export async function claimFirstAdmin(
  knex: Knex,
  userEntityRef: string,
): Promise<boolean> {
  const ref = userEntityRef.toLowerCase();
  if (configuredAdmins().length > 0 || /\/guest$/.test(ref)) {
    return false;
  }
  return knex.transaction(async trx => {
    // One claim at a time: two people signing in together cannot both win.
    await trx.raw(
      trx.client.config.client === 'pg'
        ? 'LOCK TABLE branding_admins IN EXCLUSIVE MODE'
        : 'SELECT 1',
    );
    if (await trx('branding_admins').first()) {
      return false;
    }
    await trx('branding_admins').insert({
      entity_ref: ref,
      type: 'user',
      added_at: new Date().toISOString(),
      added_by: 'first-sign-in',
    });
    return true;
  });
}

/**
 * Check if a user is a portal admin: listed themselves, in the admin table
 * or in PORTAL_ADMINS, or through a group their sign-in names
 * (`ownershipRefs`) that is listed there. The guest account, which
 * everyone using guest sign-in shares, never is one.
 *
 * Callers pass only `ownershipRefs` they know the operator stands behind:
 * a person can register a catalog file that puts them in any group.
 */
export async function checkIsAdmin(
  knex: Knex,
  userEntityRef: string,
  logger: LoggerService,
  ownershipRefs: string[] = [],
): Promise<boolean> {
  try {
    // Parse user entity ref (format: user:default/username)
    const match = userEntityRef.match(/^user:([^/]+)\/(.+)$/);
    if (!match) {
      logger.debug(`Invalid user entity ref format: ${userEntityRef}`);
      return false;
    }
    if (userEntityRef.toLowerCase() === GUEST_USER) {
      return false;
    }

    const [, , username] = match;
    const refs = [
      userEntityRef.toLowerCase(),
      ...ownershipRefs
        .map(ref => ref.toLowerCase())
        .filter(ref => ref.startsWith('group:')),
    ];

    // Check branding_admins table for the user or one of their groups
    const listed = await knex('branding_admins')
      .whereIn('entity_ref', refs)
      .first();

    if (listed) {
      logger.debug(`User ${username} is admin via branding_admins table`);
      return true;
    }

    const configured = configuredAdmins();
    if (refs.some(ref => configured.includes(ref))) {
      logger.debug(`User ${username} is admin by configuration`);
      return true;
    }

    logger.debug(`User ${userEntityRef} is not a branding admin`);
    return false;
  } catch (error) {
    logger.error('Error checking admin status', error as Error);
    return false;
  }
}

/**
 * Every portal admin, from the admin table and PORTAL_ADMINS: user and
 * group refs, in lower case. The order is fixed: those in the table in the
 * order they were added, oldest first, then those in PORTAL_ADMINS in the
 * order written.
 */
export async function listPortalAdmins(knex: Knex): Promise<string[]> {
  const rows: Array<{ entity_ref: string }> = await knex('branding_admins')
    .orderBy('id')
    .select('entity_ref');
  return [
    ...new Set([
      ...rows.map(row => row.entity_ref.toLowerCase()),
      ...configuredAdmins(),
    ]),
  ];
}

/**
 * Get all branding admins
 */
export async function getAdmins(knex: Knex): Promise<
  Array<{
    id: number;
    entity_ref: string;
    type: string;
    added_at: string;
    added_by: string | null;
  }>
> {
  return knex('branding_admins')
    .select('id', 'entity_ref', 'type', 'added_at', 'added_by')
    .orderBy('added_at', 'asc');
}

/**
 * Add a new branding admin
 */
export async function addAdmin(
  knex: Knex,
  entityRef: string,
  addedBy: string,
): Promise<void> {
  const type = entityRef.startsWith('group:') ? 'group' : 'user';
  await knex('branding_admins').insert({
    entity_ref: entityRef,
    type,
    added_at: new Date().toISOString(),
    added_by: addedBy,
  });
}

/**
 * Remove a branding admin by ID
 */
export async function removeAdmin(knex: Knex, id: number): Promise<void> {
  await knex('branding_admins').where('id', id).delete();
}

/**
 * Get admin count
 */
export async function getAdminCount(knex: Knex): Promise<number> {
  const result = await knex('branding_admins').count('id as count').first();
  return parseInt(result?.count as string, 10) || 0;
}

/**
 * Get admin by ID
 */
export async function getAdminById(
  knex: Knex,
  id: number,
): Promise<{ id: number; entity_ref: string } | undefined> {
  return knex('branding_admins').where('id', id).first();
}
