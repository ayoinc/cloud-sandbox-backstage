/**
 * =============================================================================
 * Branding Settings Types
 * =============================================================================
 *
 * TypeScript interfaces for the branding settings plugin.
 *
 * =============================================================================
 */

import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import type { S3Client } from '@aws-sdk/client-s3';

/**
 * Branding settings stored in the database
 */
export interface BrandingSettings {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
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
  updatedAt: new Date().toISOString(),
  updatedBy: null,
};

/**
 * Storage configuration for MinIO/S3
 */
export interface StorageConfig {
  endpoint: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
}

/**
 * Dependencies for route handlers
 */
export interface RouteHandlerDeps {
  knex: Knex;
  logger: LoggerService;
  s3Client: S3Client;
  bucket: string;
  httpAuth: any;
  userInfo: any;
}

/**
 * MIME type to file extension mapping
 */
export const MIME_TO_EXTENSION: Record<string, string> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/svg+xml': 'svg',
  'image/webp': 'webp',
  'image/gif': 'gif',
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
