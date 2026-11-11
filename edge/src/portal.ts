import { Hono } from 'hono';
import { inputError, notFoundError } from './errors';
import type { AppEnv } from './types';

/**
 * The smaller Backstage APIs the front end calls on every page:
 * permissions, user settings and notification status.
 */

export const permissionRoutes = new Hono<AppEnv>();

interface PermissionRequest {
  id: string;
  permission?: { name?: string; attributes?: { action?: string } };
}

// What a signed-in user may do besides read: run a software template, which
// means creating a scaffolder task and executing its actions.
const ALLOWED = ['scaffolder.task.create', 'scaffolder.action.execute'];

// Reads are allowed, and so is running a template, which shows Create and
// the task pages. Everything else is denied because nothing here does it:
// registering or deleting catalog entities, cancelling a task, the template
// editor. That hides those controls in the front end.
permissionRoutes.post('/authorize', async c => {
  const body = await c.req.json<{ items?: PermissionRequest[] }>();
  if (!Array.isArray(body.items)) {
    throw inputError('items must be an array');
  }
  return c.json({
    items: body.items.map(({ id, permission }) => ({
      id,
      result:
        permission?.attributes?.action === 'read' ||
        ALLOWED.includes(permission?.name ?? '')
          ? 'ALLOW'
          : 'DENY',
    })),
  });
});

export const userSettingsRoutes = new Hono<AppEnv>();

interface SettingRow {
  bucket: string;
  key: string;
  value: string;
}

const toSetting = (row: SettingRow) => ({
  bucket: row.bucket,
  key: row.key,
  value: JSON.parse(row.value) as unknown,
});

userSettingsRoutes.post('/multiget', async c => {
  const body = await c.req.json<{
    items?: { bucket: string; key: string }[];
  }>();
  if (!Array.isArray(body.items)) {
    throw inputError('items must be an array');
  }
  const user = c.get('user').userEntityRef;
  if (!body.items.length) {
    return c.json({ items: [] });
  }
  const select = c.env.DB.prepare(
    'SELECT bucket, key, value FROM user_settings WHERE user_entity_ref = ? AND bucket = ? AND key = ?',
  );
  const results = await c.env.DB.batch<SettingRow>(
    body.items.map(({ bucket, key }) => select.bind(user, bucket, key)),
  );
  return c.json({
    items: results.map(({ results: [row] }) => (row ? toSetting(row) : null)),
  });
});

userSettingsRoutes.get('/buckets/:bucket/keys/:key{.+}', async c => {
  const { bucket, key } = c.req.param();
  const row = await c.env.DB.prepare(
    'SELECT bucket, key, value FROM user_settings WHERE user_entity_ref = ? AND bucket = ? AND key = ?',
  )
    .bind(c.get('user').userEntityRef, bucket, key)
    .first<SettingRow>();
  if (!row) {
    throw notFoundError(`Unable to find '${key}' in bucket '${bucket}'`);
  }
  return c.json(toSetting(row));
});

userSettingsRoutes.put('/buckets/:bucket/keys/:key{.+}', async c => {
  const { bucket, key } = c.req.param();
  const body = await c.req.json<{ value?: unknown }>();
  if (body.value === undefined) {
    throw inputError('Missing required field "value"');
  }
  await c.env.DB.prepare(
    'INSERT INTO user_settings (user_entity_ref, bucket, key, value) VALUES (?, ?, ?, ?) ON CONFLICT (user_entity_ref, bucket, key) DO UPDATE SET value = excluded.value',
  )
    .bind(c.get('user').userEntityRef, bucket, key, JSON.stringify(body.value))
    .run();
  return c.json({ bucket, key, value: body.value });
});

userSettingsRoutes.delete('/buckets/:bucket/keys/:key{.+}', async c => {
  const { bucket, key } = c.req.param();
  await c.env.DB.prepare(
    'DELETE FROM user_settings WHERE user_entity_ref = ? AND bucket = ? AND key = ?',
  )
    .bind(c.get('user').userEntityRef, bucket, key)
    .run();
  return c.body(null, 204);
});

export const notificationRoutes = new Hono<AppEnv>();

// No notifications are produced at the edge yet; report an empty inbox.
notificationRoutes.get('/status', c => c.json({ unread: 0, read: 0 }));
notificationRoutes.get('/notifications', c =>
  c.json({ totalCount: 0, notifications: [] }),
);
notificationRoutes.get('/topics', c => c.json({ topics: [] }));
