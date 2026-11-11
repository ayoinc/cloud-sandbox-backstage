CREATE TABLE items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 200),
  created_at TEXT NOT NULL
);

CREATE INDEX items_created_at ON items (created_at);
