/**
 * Logo files, kept in the plugin's own database: a portal needs no object
 * store to be branded, and the logo is served from the same address on
 * every way of hosting it.
 */

import type { Knex } from 'knex';

export type LogoKind = 'full' | 'icon';

/** Larger than any reasonable logo, small enough for one database value. */
export const MAX_LOGO_BYTES = 1024 * 1024;

export const isLogoKind = (value: string): value is LogoKind =>
  value === 'full' || value === 'icon';

/**
 * Stores a logo and returns the address it is served from. The `v` changes
 * with every upload, so the file itself can be cached for good.
 */
export async function saveLogo(
  knex: Knex,
  kind: LogoKind,
  file: { buffer: Buffer; mimetype: string },
): Promise<string> {
  await knex('branding_logos')
    .insert({
      kind,
      content_type: file.mimetype,
      bytes: file.buffer,
      updated_at: new Date().toISOString(),
    })
    .onConflict('kind')
    .merge();
  return `/api/branding-settings/logo/${kind}?v=${Date.now()}`;
}

export async function readLogo(
  knex: Knex,
  kind: LogoKind,
): Promise<{ contentType: string; bytes: Buffer } | undefined> {
  const row = await knex('branding_logos').where('kind', kind).first();
  return row
    ? { contentType: row.content_type, bytes: Buffer.from(row.bytes) }
    : undefined;
}

export async function deleteLogos(knex: Knex): Promise<void> {
  await knex('branding_logos').delete();
}
