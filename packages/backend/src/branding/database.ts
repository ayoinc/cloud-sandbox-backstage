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
      updated_at: new Date().toISOString(),
      updated_by: null,
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

    // Bootstrap initial admin from environment variable
    const initialAdmin =
      process.env.BRANDING_INITIAL_ADMIN ||
      process.env.BRANDING_ADMIN_USERS?.split(',')[0]?.trim();
    if (initialAdmin) {
      const entityRef = initialAdmin.includes(':')
        ? initialAdmin
        : `user:default/${initialAdmin}`;
      await knex('branding_admins').insert({
        entity_ref: entityRef,
        type: entityRef.startsWith('group:') ? 'group' : 'user',
        added_at: new Date().toISOString(),
        added_by: 'system',
      });
      logger.info(`Bootstrapped initial branding admin: ${entityRef}`);
    } else {
      logger.warn(
        'No initial branding admin configured. Set BRANDING_INITIAL_ADMIN env var.',
      );
    }
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
        `Group-based admins configured: ${groupAdmins.map((g: { entity_ref: string }) => g.entity_ref).join(', ')}`,
      );
      // Note: Full group membership checking requires catalog API integration
      // This is handled in the permission policy
    }

    // Fallback: Check BRANDING_ADMIN_USERS env var (for backwards compatibility)
    const adminUsersEnv = process.env.BRANDING_ADMIN_USERS || '';
    const adminUsernames = adminUsersEnv
      .split(',')
      .map(u => u.trim().toLowerCase())
      .filter(u => u.length > 0);

    if (adminUsernames.includes(username.toLowerCase())) {
      logger.debug(`User ${username} is admin via BRANDING_ADMIN_USERS env var`);
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
