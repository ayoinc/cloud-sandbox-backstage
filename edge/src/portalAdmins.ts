import { Hono } from 'hono';
import {
  claimFirstAdmin,
  configuredAdmins,
  isPortalAdmin,
  requirePortalAdmin,
} from './admin';
import {
  conflictError,
  handlePlainError,
  inputError,
  notFoundError,
} from './errors';
import { isRecord, readJson } from './json';
import type { AppEnv } from './types';

/**
 * The list of portal admins, served where the Node backend serves it:
 * /api/branding-settings. The name is from when admins looked after one
 * portal-wide branding; a look now belongs to an organisation
 * (organisations.ts), and admins look after ownership, catalog files and
 * the template editor.
 */

const MAX_BODY_BYTES = 16 * 1024;

const SELECT_ADMINS =
  'SELECT id, entity_ref, type, added_at, added_by FROM branding_admins ORDER BY added_at, id';

export const portalAdminRoutes = new Hono<AppEnv>();

portalAdminRoutes.onError(handlePlainError);

// The first signed-in user of a portal without admins becomes its admin
// here: the front end asks this on every page.
portalAdminRoutes.get('/admin-check', async c =>
  c.json({
    isAdmin: (await isPortalAdmin(c)) || (await claimFirstAdmin(c)),
    userEntityRef: c.get('user').userEntityRef,
  }),
);

// The admins that can be added and removed here. Those named in
// PORTAL_ADMINS are configuration, and are changed there.
portalAdminRoutes.get('/admins', async c => {
  await requirePortalAdmin(c);
  const { results } = await c.env.DB.prepare(SELECT_ADMINS).all();
  return c.json({ admins: results });
});

portalAdminRoutes.post('/admins', async c => {
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

portalAdminRoutes.delete('/admins/:id', async c => {
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
