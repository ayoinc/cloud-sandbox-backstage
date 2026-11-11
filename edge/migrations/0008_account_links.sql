-- Sign-in methods a person has linked to their account. Signing in with a
-- linked one makes them that account: the same organisation, look, files
-- and settings, whichever way they signed in.
CREATE TABLE account_links (
  -- 'github' or 'google', and the account there: a GitHub login or a
  -- Google email address, in lower case.
  provider TEXT NOT NULL,
  id TEXT NOT NULL,
  -- The account it signs in as. Lower case: user:default/jane.
  user_ref TEXT NOT NULL,
  linked_at TEXT NOT NULL,
  PRIMARY KEY (provider, id)
);

CREATE INDEX account_links_user ON account_links (user_ref);
