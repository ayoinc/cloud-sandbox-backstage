/**
 * =============================================================================
 * Branding Settings Database Operations
 * =============================================================================
 *
 * Database access layer for branding settings and admin management.
 *
 * =============================================================================
 */

import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import {
  BrandingSettings,
  BrandingSettingsRow,
  DEFAULT_SETTINGS,
} from './types';

/**
 * Initialize database tables for branding settings
 */
export async function initializeTables(
  knex: Knex,
  logger: LoggerService,
): Promise<void> {
  // Create branding_settings table if not exists
  const hasSettingsTable = await knex.schema.hasTable('branding_settings');
  if (!hasSettingsTable) {
    logger.info('Creating branding_settings table');
    await knex.schema.createTable('branding_settings', table => {
      table.string('id').primary().defaultTo('default');
      table.string('organization_name').nullable();
      table.text('logo_full_url').nullable();
      table.text('logo_icon_url').nullable();
      table.string('primary_color').nullable();
      table.string('theme_preset').nullable();
      table.timestamp('updated_at').defaultTo(knex.fn.now());
      table.string('updated_by').nullable();
    });
    // Insert default row
    await knex('branding_settings').insert({
      id: 'default',
      organization_name: null,
      logo_full_url: null,
      logo_icon_url: null,
      primary_color: null,
      theme_preset: null,
      updated_at: new Date().toISOString(),
      updated_by: null,
    });
  }

  // Tables created before theme presets existed lack the column
  if (
    hasSettingsTable &&
    !(await knex.schema.hasColumn('branding_settings', 'theme_preset'))
  ) {
    logger.info('Adding theme_preset column to branding_settings');
    await knex.schema.alterTable('branding_settings', table => {
      table.string('theme_preset').nullable();
    });
  }

  // Logo files, one row per kind.
  if (!(await knex.schema.hasTable('branding_logos'))) {
    logger.info('Creating branding_logos table');
    await knex.schema.createTable('branding_logos', table => {
      table.string('kind').primary();
      table.string('content_type').notNullable();
      table.binary('bytes').notNullable();
      table.string('updated_at').notNullable();
    });
  }

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
 * Get current branding settings from database
 */
export async function getCurrentSettings(
  knex: Knex,
): Promise<BrandingSettings> {
  const row = (await knex('branding_settings')
    .where('id', 'default')
    .first()) as BrandingSettingsRow | undefined;

  if (!row) {
    return DEFAULT_SETTINGS;
  }

  return {
    organizationName: row.organization_name,
    logoFullUrl: row.logo_full_url,
    logoIconUrl: row.logo_icon_url,
    primaryColor: row.primary_color,
    themePreset: row.theme_preset,
    updatedAt: row.updated_at,
    updatedBy: row.updated_by,
  };
}

/**
 * Update branding settings in database
 */
export async function updateSettings(
  knex: Knex,
  updates: Partial<BrandingSettingsRow>,
): Promise<void> {
  await knex('branding_settings').where('id', 'default').update(updates);
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
 * Check if a user is an admin for branding settings
 */
export async function checkIsAdmin(
  knex: Knex,
  userEntityRef: string,
  logger: LoggerService,
): Promise<boolean> {
  try {
    // Parse user entity ref (format: user:default/username)
    const match = userEntityRef.match(/^user:([^/]+)\/(.+)$/);
    if (!match) {
      logger.debug(`Invalid user entity ref format: ${userEntityRef}`);
      return false;
    }

    const [, , username] = match;

    // Check branding_admins table for direct user match
    const directMatch = await knex('branding_admins')
      .where('entity_ref', userEntityRef.toLowerCase())
      .first();

    if (directMatch) {
      logger.debug(`User ${username} is admin via branding_admins table`);
      return true;
    }

    // Check for group-based admin (would need catalog integration for full support)
    const groupAdmins = await knex('branding_admins')
      .where('type', 'group')
      .select('entity_ref');

    if (groupAdmins.length > 0) {
      logger.debug(
        `Group-based admins configured: ${groupAdmins
          .map((g: { entity_ref: string }) => g.entity_ref)
          .join(', ')}`,
      );
      // Note: Full group membership checking requires catalog API integration
      // This is handled in the permission policy
    }

    if (configuredAdmins().includes(userEntityRef.toLowerCase())) {
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
