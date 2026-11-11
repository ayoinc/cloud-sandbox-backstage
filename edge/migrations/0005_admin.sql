-- The theme an admin picked for the whole portal: a preset id, or NULL for
-- the built-in look.
ALTER TABLE branding_settings ADD COLUMN theme_preset TEXT;

-- Portal admins: who may change branding and reassign ownership. Same
-- columns as the Node backend's table. Admins named in the PORTAL_ADMINS
-- variable are not rows here.
CREATE TABLE branding_admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- Lower case: user:default/jane or group:default/platform.
  entity_ref TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('user', 'group')),
  added_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- An admin's entity ref, or 'first-sign-in' for whoever claimed an
  -- admin-less portal.
  added_by TEXT
);

-- Uploaded logos. They are small and change rarely, so they live beside the
-- settings that point at them instead of in a bucket of their own.
CREATE TABLE branding_logos (
  kind TEXT PRIMARY KEY CHECK (kind IN ('full', 'icon')),
  content_type TEXT NOT NULL,
  bytes BLOB NOT NULL,
  updated_at TEXT NOT NULL
);

-- Owners assigned in the portal to entities whose catalog owner is gone.
-- Same columns as the Node backend's table.
CREATE TABLE ownership_overrides (
  -- Lower case, as in final_entities.
  entity_ref TEXT PRIMARY KEY,
  new_owner TEXT NOT NULL,
  previous_owner TEXT,
  overridden_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  overridden_by TEXT
);
