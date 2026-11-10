-- Catalog read model. Same tables and columns the Backstage catalog backend
-- queries, so its SQL ports over unchanged.
CREATE TABLE final_entities (
  entity_id TEXT PRIMARY KEY,
  entity_ref TEXT NOT NULL UNIQUE,
  final_entity TEXT NOT NULL
);

CREATE TABLE search (
  entity_id TEXT NOT NULL REFERENCES final_entities (entity_id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value TEXT,
  original_value TEXT
);

CREATE INDEX search_key_value_idx ON search (key, value, entity_id);
CREATE INDEX search_entity_key_idx ON search (entity_id, key);

-- Which entity emitted which: the parent links behind entity ancestry.
CREATE TABLE refresh_state_references (
  source_entity_ref TEXT NOT NULL,
  target_entity_ref TEXT NOT NULL
);

CREATE INDEX refresh_state_references_target_idx ON refresh_state_references (target_entity_ref);

-- Portal search. `document` holds the ready-to-send search document JSON.
CREATE VIRTUAL TABLE search_documents USING fts5 (
  title,
  text,
  type UNINDEXED,
  document UNINDEXED,
  tokenize = 'porter unicode61'
);

CREATE TABLE user_settings (
  user_entity_ref TEXT NOT NULL,
  bucket TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  PRIMARY KEY (user_entity_ref, bucket, key)
);

CREATE TABLE branding_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  organization_name TEXT,
  logo_full_url TEXT,
  logo_icon_url TEXT,
  primary_color TEXT,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_by TEXT
);

INSERT INTO branding_settings (id) VALUES (1);
