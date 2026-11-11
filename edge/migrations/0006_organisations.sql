-- Organisations: a name, an address and a look that belong to the people
-- who created them, not to the portal. The Node backend keeps the same
-- tables.
CREATE TABLE organisations (
  -- The address: the portal shows this organisation at /o/<slug>.
  slug TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  primary_color TEXT,
  -- A preset id, or NULL for the built-in look.
  theme_preset TEXT
);

-- Who belongs to which organisation. The user is the key: a person is in
-- one organisation at most, which is how signing in knows where to land.
CREATE TABLE organisation_members (
  -- Lower case: user:default/jane.
  user_ref TEXT PRIMARY KEY,
  slug TEXT NOT NULL REFERENCES organisations (slug) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'member')),
  added_at TEXT NOT NULL,
  -- Whoever added them; the creator added themself.
  added_by TEXT NOT NULL
);

CREATE INDEX organisation_members_slug ON organisation_members (slug);

-- People an owner has asked to join, who have not answered yet. Nobody is
-- put in an organisation by someone else: joining turns the row into a
-- membership.
CREATE TABLE organisation_invitations (
  slug TEXT NOT NULL REFERENCES organisations (slug) ON DELETE CASCADE,
  user_ref TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner', 'member')),
  invited_at TEXT NOT NULL,
  invited_by TEXT NOT NULL,
  PRIMARY KEY (slug, user_ref)
);

CREATE INDEX organisation_invitations_user ON organisation_invitations (user_ref);

-- Uploaded logos, beside the organisation they belong to. updated_at is
-- also the version in a logo's address, which browsers keep for a year.
CREATE TABLE organisation_logos (
  slug TEXT NOT NULL REFERENCES organisations (slug) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('full', 'icon')),
  content_type TEXT NOT NULL,
  bytes BLOB NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (slug, kind)
);

-- branding_settings and branding_logos, the one portal-wide name, logo and
-- theme, are no longer read. They stay for now so that this migration only
-- adds: the Worker deployed before it keeps working until the new one is
-- out, and can be rolled back to.
