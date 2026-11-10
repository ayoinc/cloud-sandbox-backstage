-- People who have signed in, each as a finished catalog User entity. A
-- catalog sync replaces the catalog tables wholesale, so the users are kept
-- here and copied into those tables at sign-in and at the end of every sync.
-- A user that a catalog file also defines is not copied: the catalog's
-- entity is the one served.
CREATE TABLE signed_in_users (
  entity_ref TEXT PRIMARY KEY,
  -- Also the entity's metadata.uid. Stays the same across sign-ins.
  entity_id TEXT NOT NULL UNIQUE,
  final_entity TEXT NOT NULL CHECK (json_valid(final_entity)),
  -- The entity's rows for the search table: [[key, value, original_value], ...]
  search_rows TEXT NOT NULL CHECK (json_valid(search_rows)),
  -- The entity's document for search_documents.
  search_document TEXT NOT NULL CHECK (json_valid(search_document)),
  updated_at TEXT NOT NULL
);
