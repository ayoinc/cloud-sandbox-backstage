/**
 * =============================================================================
 * Branding Settings Types
 * =============================================================================
 *
 * TypeScript interfaces for the branding settings plugin.
 *
 * =============================================================================
 */

/**
 * Branding settings stored in the database
 */
export interface BrandingSettings {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
  updatedAt: string;
  updatedBy: string | null;
}

/**
 * Branding admin entry from the database
 */
export interface BrandingAdmin {
  id: number;
  entity_ref: string;
  type: 'user' | 'group';
  added_at: string;
  added_by: string | null;
}

/**
 * Database row for branding settings
 */
export interface BrandingSettingsRow {
  id: string;
  organization_name: string | null;
  logo_full_url: string | null;
  logo_icon_url: string | null;
  primary_color: string | null;
  theme_preset: string | null;
  updated_at: string;
  updated_by: string | null;
}

/**
 * Default branding settings when none are configured
 */
export const DEFAULT_SETTINGS: BrandingSettings = {
  organizationName: null,
  logoFullUrl: null,
  logoIconUrl: null,
  primaryColor: null,
  themePreset: null,
  updatedAt: new Date().toISOString(),
  updatedBy: null,
};

/**
 * Allowed MIME types for logo uploads
 */
export const ALLOWED_MIME_TYPES = [
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
  'image/gif',
];
