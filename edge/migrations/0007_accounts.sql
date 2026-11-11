-- Accounts: who a registered catalog file belongs to. An account is an
-- organisation ('organisation:<id>') or, for someone who is in none, the
-- person ('user:default/jane'). The Node backend keeps the same columns.

-- An organisation's address and name can both change, so what belongs to it
-- is filed under an id that never does: 32 lower-case hex digits.
ALTER TABLE organisations ADD COLUMN id TEXT;
UPDATE organisations SET id = lower(hex(randomblob(16)));
CREATE UNIQUE INDEX organisations_id ON organisations (id);

-- The name as it is compared: no two organisations on a portal have names
-- that differ only in case or spacing. New rows get the key from nameKey()
-- in packages/backend/src/organisations/rules.ts. Organisations that
-- already share a name keep it; the later ones are told apart by their
-- address until an owner renames them.
ALTER TABLE organisations ADD COLUMN name_key TEXT;
UPDATE organisations SET name_key = lower(trim(name));
UPDATE organisations SET name_key = name_key || ' (' || slug || ')'
  WHERE rowid NOT IN (SELECT min(rowid) FROM organisations GROUP BY name_key);
CREATE UNIQUE INDEX organisations_name_key ON organisations (name_key);

-- The account a registered catalog file belongs to. Its entities are shown
-- to that account only. NULL is nobody's: shown to no one until a portal
-- administrator registers the file again and so takes it.
ALTER TABLE locations ADD COLUMN account TEXT;

-- When a file was unregistered. Its row stays, and its entities are shown
-- to no one, until a catalog sync has run without them: only then is there
-- nothing left in the catalog that came from it, and the row goes.
ALTER TABLE locations ADD COLUMN removed_at TEXT;

-- Files registered before accounts existed go to the first portal
-- administrator: to their organisation when they are in one.
UPDATE locations SET account = (
  SELECT coalesce(
    (SELECT 'organisation:' || o.id
       FROM organisation_members m JOIN organisations o ON o.slug = m.slug
      WHERE m.user_ref = a.entity_ref),
    a.entity_ref)
  FROM branding_admins a
  WHERE a.type = 'user'
  ORDER BY a.id
  LIMIT 1
);
