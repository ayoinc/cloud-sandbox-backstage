import { Hono, type Context } from 'hono';
import {
  claimFirstAdmin,
  configuredAdmins,
  isPortalAdmin,
  requirePortalAdmin,
} from './admin';
import {
  HttpError,
  conflictError,
  handlePlainError,
  inputError,
  notFoundError,
} from './errors';
import { isRecord, readJson } from './json';
import type { AppEnv } from './types';

/**
 * Branding: the organisation name, colour, theme and logos an admin chose
 * for the portal, and the list of admins. Same API as the Node backend's
 * branding plugin. Logos are kept in D1 and served from here.
 */

const MAX_BODY_BYTES = 16 * 1024;
// A D1 row holds at most 2 MB, and a logo has no reason to come near it.
const MAX_LOGO_BYTES = 1024 * 1024;
const LOGO_TYPES = [
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
  'image/gif',
];
/** Upload form field, and the logo kind it holds. */
const LOGO_FIELDS = [
  ['logoFull', 'full'],
  ['logoIcon', 'icon'],
] as const;

/** The text settings: JSON name, column, and what a value must look like. */
const TEXT_FIELDS = [
  {
    name: 'organizationName',
    column: 'organization_name',
    pattern: /^.{1,80}$/su,
    rule: 'at most 80 characters',
  },
  {
    name: 'primaryColor',
    column: 'primary_color',
    pattern: /^#[0-9a-f]{6}$/i,
    rule: 'a six-digit hex colour such as #1a2b3c',
  },
  {
    name: 'themePreset',
    column: 'theme_preset',
    pattern: /^[a-z][a-z0-9-]{0,39}$/,
    rule: 'a preset id: lower-case letters, digits and dashes, at most 40',
  },
];

const SELECT_SETTINGS =
  'SELECT organization_name, logo_full_url, logo_icon_url, primary_color, theme_preset, updated_at, updated_by FROM branding_settings WHERE id = 1';
const SELECT_ADMINS =
  'SELECT id, entity_ref, type, added_at, added_by FROM branding_admins ORDER BY added_at, id';

type Row = Record<string, string | null>;

const toSettings = (row: Row | null | undefined) => ({
  organizationName: row?.organization_name ?? null,
  logoFullUrl: row?.logo_full_url ?? null,
  logoIconUrl: row?.logo_icon_url ?? null,
  primaryColor: row?.primary_color ?? null,
  themePreset: row?.theme_preset ?? null,
  updatedAt: row?.updated_at ?? null,
  updatedBy: row?.updated_by ?? null,
});

/**
 * Sets the given settings columns, after running `before`, and responds
 * with the settings as they are then. One batch, so one transaction: a logo
 * and the URL that points at it change together.
 */
async function changeSettings(
  c: Context<AppEnv>,
  admin: string,
  columns: Record<string, string | null>,
  before: D1PreparedStatement[] = [],
) {
  const changed = { ...columns, updated_at: new Date().toISOString() };
  // Column names come from this file, never from the request.
  const update = c.env.DB.prepare(
    `UPDATE branding_settings SET ${Object.keys(changed)
      .map(column => `${column} = ?`)
      .join(', ')}, updated_by = ? WHERE id = 1`,
  ).bind(...Object.values(changed), admin);
  const results = await c.env.DB.batch<Row>([
    ...before,
    update,
    c.env.DB.prepare(SELECT_SETTINGS),
  ]);
  return c.json(toSettings(results.at(-1)?.results[0]));
}

/** Public: the sign-in page shows branding before anyone has signed in. */
export const publicBrandingRoutes = new Hono<AppEnv>();

publicBrandingRoutes.onError(handlePlainError);

publicBrandingRoutes.get('/', async c =>
  c.json(toSettings(await c.env.DB.prepare(SELECT_SETTINGS).first<Row>())),
);

publicBrandingRoutes.get('/logo/:kind', async c => {
  const logo = await c.env.DB.prepare(
    'SELECT content_type, bytes FROM branding_logos WHERE kind = ?',
  )
    .bind(c.req.param('kind'))
    // D1 returns a BLOB as an array of byte values.
    .first<{ content_type: string; bytes: ArrayBuffer | number[] }>();
  if (!logo) {
    throw notFoundError('No such logo');
  }
  return new Response(new Uint8Array(logo.bytes), {
    headers: {
      'content-type': logo.content_type,
      // The address carries a version that changes with every upload.
      'cache-control': 'public, max-age=31536000, immutable',
      'x-content-type-options': 'nosniff',
      // An SVG opened on its own is a document: this keeps it from running
      // script or loading anything, with this origin's cookies in reach.
      'content-security-policy':
        "default-src 'none'; style-src 'unsafe-inline'; sandbox",
    },
  });
});

export const brandingRoutes = new Hono<AppEnv>();

brandingRoutes.onError(handlePlainError);

brandingRoutes.post('/', async c => {
  const admin = await requirePortalAdmin(c);
  const body = await readJson(c, MAX_BODY_BYTES);
  if (!isRecord(body)) {
    throw inputError('Request body must be a JSON object');
  }
  const columns: Record<string, string | null> = {};
  for (const { name, column, pattern, rule } of TEXT_FIELDS) {
    const value = body[name];
    // A field that was not sent stays as it is; null or '' clears it.
    if (value === undefined) {
      continue;
    }
    if (value !== null && typeof value !== 'string') {
      throw inputError(`${name} must be a string or null`);
    }
    const text = value?.trim() || null;
    if (text !== null && !pattern.test(text)) {
      throw inputError(`${name} must be ${rule}`);
    }
    columns[column] = text;
  }
  return changeSettings(c, admin, columns);
});

brandingRoutes.post('/logo/upload', async c => {
  const admin = await requirePortalAdmin(c);
  const tooLarge = (what: string, bytes: number) =>
    new HttpError(
      413,
      'PayloadTooLargeError',
      `${what} is ${bytes} bytes, the limit is ${MAX_LOGO_BYTES} for each logo`,
    );
  // Two logos and the form around them. A body that declares more is
  // refused without being read.
  const declared = Number(c.req.header('content-length') ?? 0);
  if (declared > 2 * MAX_LOGO_BYTES + MAX_BODY_BYTES) {
    throw tooLarge('Request body', declared);
  }
  let form: FormData;
  try {
    form = await c.req.formData();
  } catch {
    throw inputError('Request body is not a multipart form');
  }

  const now = new Date();
  const columns: Record<string, string> = {};
  const logos: D1PreparedStatement[] = [];
  for (const [field, kind] of LOGO_FIELDS) {
    const file = form.get(field);
    if (file === null) {
      continue;
    }
    if (typeof file === 'string') {
      throw inputError(`${field} must be a file`);
    }
    if (!LOGO_TYPES.includes(file.type)) {
      throw inputError(
        'Invalid file type. Only PNG, JPEG, SVG, WebP, and GIF are allowed.',
      );
    }
    if (file.size > MAX_LOGO_BYTES) {
      throw tooLarge(field, file.size);
    }
    logos.push(
      c.env.DB.prepare(
        'INSERT INTO branding_logos (kind, content_type, bytes, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT (kind) DO UPDATE SET content_type = excluded.content_type, bytes = excluded.bytes, updated_at = excluded.updated_at',
      ).bind(kind, file.type, await file.arrayBuffer(), now.toISOString()),
    );
    // Relative, so it works on whatever address the portal is served from.
    // Browsers keep a logo for a year; the version makes a new one show.
    columns[
      `logo_${kind}_url`
    ] = `/api/branding-settings/logo/${kind}?v=${now.getTime()}`;
  }
  if (!logos.length) {
    throw inputError('Send a file as logoFull, logoIcon or both');
  }
  return changeSettings(c, admin, columns, logos);
});

brandingRoutes.delete('/logo', async c =>
  changeSettings(
    c,
    await requirePortalAdmin(c),
    { logo_full_url: null, logo_icon_url: null },
    [c.env.DB.prepare('DELETE FROM branding_logos')],
  ),
);

brandingRoutes.delete('/', async c =>
  changeSettings(
    c,
    await requirePortalAdmin(c),
    {
      organization_name: null,
      logo_full_url: null,
      logo_icon_url: null,
      primary_color: null,
      theme_preset: null,
    },
    [c.env.DB.prepare('DELETE FROM branding_logos')],
  ),
);

// The first signed-in user of a portal without admins becomes its admin
// here: the front end asks this on every page.
brandingRoutes.get('/admin-check', async c =>
  c.json({
    isAdmin: (await isPortalAdmin(c)) || (await claimFirstAdmin(c)),
    userEntityRef: c.get('user').userEntityRef,
  }),
);

// The admins that can be added and removed here. Those named in
// PORTAL_ADMINS are configuration, and are changed there.
brandingRoutes.get('/admins', async c => {
  await requirePortalAdmin(c);
  const { results } = await c.env.DB.prepare(SELECT_ADMINS).all();
  return c.json({ admins: results });
});

brandingRoutes.post('/admins', async c => {
  const admin = await requirePortalAdmin(c);
  const body = await readJson(c, MAX_BODY_BYTES);
  if (
    !isRecord(body) ||
    !body.entityRef ||
    typeof body.entityRef !== 'string'
  ) {
    throw inputError('entityRef is required');
  }
  let entityRef = body.entityRef.trim().toLowerCase();
  if (!entityRef.includes(':')) {
    entityRef = `user:default/${entityRef}`;
  }
  if (!/^(user|group):[^/]+\/.+$/.test(entityRef)) {
    throw inputError(
      'Invalid entityRef format. Use user:default/username or group:default/teamname',
    );
  }
  const [added, admins] = await c.env.DB.batch([
    c.env.DB.prepare(
      'INSERT INTO branding_admins (entity_ref, type, added_by) VALUES (?, ?, ?) ON CONFLICT (entity_ref) DO NOTHING',
    ).bind(entityRef, entityRef.startsWith('group:') ? 'group' : 'user', admin),
    c.env.DB.prepare(SELECT_ADMINS),
  ]);
  if (!added.meta.changes) {
    throw conflictError('Admin already exists');
  }
  return c.json({ admins: admins.results });
});

brandingRoutes.delete('/admins/:id', async c => {
  const admin = await requirePortalAdmin(c);
  const id = Number(c.req.param('id'));
  const target = Number.isInteger(id)
    ? await c.env.DB.prepare(
        'SELECT entity_ref FROM branding_admins WHERE id = ?',
      )
        .bind(id)
        .first<string>('entity_ref')
    : null;
  if (!target) {
    throw notFoundError('Admin not found');
  }
  if (target === admin.toLowerCase()) {
    throw inputError(
      'Cannot remove yourself. Ask another admin to remove you.',
    );
  }
  // The last row stays unless PORTAL_ADMINS names an admin: an empty list
  // with nobody configured would hand the portal to whoever asks next. The
  // count is part of the delete, so two removals at once cannot empty it.
  const [removed, admins] = await c.env.DB.batch([
    c.env.DB.prepare(
      'DELETE FROM branding_admins WHERE id = ?1 AND (?2 OR (SELECT count(*) FROM branding_admins) > 1)',
    ).bind(id, configuredAdmins(c.env).length ? 1 : 0),
    c.env.DB.prepare(SELECT_ADMINS),
  ]);
  if (!removed.meta.changes) {
    throw inputError('Cannot remove the last admin');
  }
  return c.json({ admins: admins.results });
});
