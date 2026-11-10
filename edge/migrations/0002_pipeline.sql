-- Catalog staging. The pipeline loads a whole catalog here, then one
-- transaction replaces the live tables, so readers never see half a catalog.
-- The checks reject rows the read APIs could not serve: entities and search
-- documents are sent to clients as stored, without being parsed.
CREATE TABLE staging_final_entities (
  entity_id TEXT NOT NULL,
  entity_ref TEXT NOT NULL,
  final_entity TEXT NOT NULL CHECK (json_valid(final_entity))
);

CREATE TABLE staging_search (
  entity_id TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT,
  original_value TEXT
);

CREATE TABLE staging_refresh_state_references (
  source_entity_ref TEXT NOT NULL,
  target_entity_ref TEXT NOT NULL
);

-- search_documents is a full-text table, so its rows are staged here.
CREATE TABLE staging_search_documents (
  title TEXT NOT NULL,
  text TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('software-catalog', 'techdocs')),
  document TEXT NOT NULL CHECK (json_valid(document))
);

CREATE TABLE staging_techdocs_sites (
  entity_ref TEXT NOT NULL,
  site_id TEXT NOT NULL CHECK (site_id <> '' AND site_id NOT GLOB '*[^a-z0-9-]*')
);

-- Which built documentation site in R2 (sites/<site_id>/...) belongs to an
-- entity. Several entities can share one site.
CREATE TABLE techdocs_sites (
  entity_ref TEXT PRIMARY KEY COLLATE NOCASE,
  site_id TEXT NOT NULL
);

-- Catalog locations registered by software templates. The pipeline reads
-- them on every run, so they are not part of the catalog swap.
CREATE TABLE locations (
  type TEXT NOT NULL,
  target TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (type, target)
);

-- Single values kept between requests: the catalog sync in progress and the
-- scaffolder actions list.
CREATE TABLE portal_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Scaffolder tasks and their events, as the Backstage scaffolder stores them.
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  spec TEXT NOT NULL,
  status TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_heartbeat_at TEXT
);

CREATE INDEX tasks_created_by_idx ON tasks (created_by, created_at);

CREATE TABLE task_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX task_events_task_idx ON task_events (task_id, id);
