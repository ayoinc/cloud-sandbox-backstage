import type { Context } from 'hono';
import type { SqlFragment } from './catalog/filter';
import type { AppEnv } from './types';

/**
 * Accounts: who a registered catalog file, and so everything read from it,
 * belongs to.
 *
 * An account is an organisation, written `organisation:<id>`, or for someone
 * who is in none the person: their user ref in lower case. A user sees their
 * own account and, when they are in one, their organisation's. What they
 * register is filed under the organisation when they are in one, and under
 * their own ref otherwise.
 *
 * Nothing is stamped on entities. Who may see one is worked out from the
 * tables each time it is read, inside the statement that reads it, so a
 * change of membership or of a file's account shows at once and a catalog
 * sync has nothing to carry over.
 */

/** The signed-in user's ref in lower case, as accounts and memberships name people. */
export const callerRef = (c: Context<AppEnv>) =>
  c.get('user').userEntityRef.toLowerCase();

// Completed with SQL for a user's lower-case ref. An organisation without
// an id is left out: a NULL among the accounts would make every NOT IN
// test below unknown instead of false.
const ORGANISATION_ACCOUNT =
  "SELECT 'organisation:' || org.id FROM organisation_members mem JOIN organisations org ON org.slug = mem.slug WHERE org.id IS NOT NULL AND mem.user_ref = ";

/** A query for the accounts `user` (a lower-case user ref) sees. */
const accountsSeenBy = (user: string): SqlFragment => ({
  sql: `SELECT ? UNION ALL ${ORGANISATION_ACCOUNT}?`,
  params: [user, user],
});

/**
 * Condition on a `locations` row: it is registered under one of the
 * accounts `user` sees. A file nobody has claimed is nobody's, and one that
 * was unregistered is not registered.
 */
export function registeredBy(user: string, alias = 'l'): SqlFragment {
  const accounts = accountsSeenBy(user);
  return {
    sql: `(${alias}.removed_at IS NULL AND ${alias}.account IN (${accounts.sql}))`,
    params: accounts.params,
  };
}

/**
 * SQL for the file the entity aliased `alias` descends from, in lower case.
 * The catalog writes it into the origin annotation, whatever the file
 * itself says. It is read from the entity, not from its search rows: those
 * hold no value longer than 200 characters, and an address can be.
 */
export const originOf = (alias: string) =>
  `lower(json_extract(${alias}.final_entity, '$.metadata.annotations."backstage.io/managed-by-origin-location"'))`;

/**
 * Condition on a `final_entities` row: the entity descends from a file that
 * was registered through the portal, whoever by, and not from one the
 * operator configured.
 */
export const fromRegisteredFile = (alias: string) =>
  `coalesce(${originOf(
    alias,
  )}, '') IN (SELECT lower(reg.type || ':' || reg.target) FROM locations reg)`;

/**
 * Condition on a `final_entities` row: `user` (a lower-case user ref) may
 * see the entity.
 *
 * An entity that comes from a registered file is seen by that file's
 * account only, and by nobody while the file is unclaimed. Nor by anybody
 * once the file was unregistered: its entities stay in the catalog until a
 * sync has run without them, and are not to become everyone's meanwhile.
 * Addresses are compared in lower case, as the catalog's search values are,
 * so two that differ only in case count as one file. Entities from anywhere
 * else (the files the operator configured) are shared.
 *
 * A person who signed in is seen by themself and by the members of their
 * organisation.
 *
 * The files hidden from the caller are worked out once per statement, not
 * once per entity.
 */
export function visibleTo(user: string, alias = 'e'): SqlFragment {
  const accounts = accountsSeenBy(user);
  return {
    sql: `coalesce(${originOf(
      alias,
    )}, '') NOT IN (SELECT lower(loc.type || ':' || loc.target) FROM locations loc WHERE loc.removed_at IS NOT NULL OR loc.account IS NULL OR loc.account NOT IN (${
      accounts.sql
    })) AND (substr(${alias}.entity_ref, 1, 5) <> 'user:' OR ${alias}.entity_ref = ? OR NOT EXISTS (SELECT 1 FROM signed_in_users person WHERE person.entity_ref = ${alias}.entity_ref) OR ${alias}.entity_ref IN (SELECT theirs.user_ref FROM organisation_members mine JOIN organisation_members theirs ON theirs.slug = mine.slug WHERE mine.user_ref = ?))`,
    params: [...accounts.params, user, user],
  };
}

/**
 * Condition on SQL for an entity ref in lower case: it is not the ref of an
 * entity `user` may not see. The ref of no entity at all passes: there is
 * nothing to hide.
 */
export function refShownTo(user: string, ref: string): SqlFragment {
  const visible = visibleTo(user, 'target');
  return {
    sql: `NOT EXISTS (SELECT 1 FROM final_entities target WHERE target.entity_ref = ${ref} AND NOT (${visible.sql}))`,
    params: visible.params,
  };
}

/**
 * SQL for the entity aliased `alias` as `user` is served it: as stored,
 * less the relations to entities that user may not see. An entity names
 * those that point at it (a group what it owns, a system its parts), which
 * would tell of other accounts' entities by name.
 *
 * It costs one look-up by ref for every relation of every entity served,
 * and writes the entity's JSON out again. Use it for the rows that are
 * sent, not for those a statement only sorts or counts.
 */
export function servedTo(user: string, alias = 'e'): SqlFragment {
  const shown = refShownTo(
    user,
    "lower(json_extract(relation.value, '$.targetRef'))",
  );
  return {
    sql: `CASE WHEN json_type(${alias}.final_entity, '$.relations') = 'array' THEN json_set(${alias}.final_entity, '$.relations', json((SELECT json_group_array(json(relation.value)) FROM json_each(${alias}.final_entity, '$.relations') relation WHERE ${shown.sql}))) ELSE ${alias}.final_entity END`,
    params: shown.params,
  };
}

/** As `locations.created_at` is written by default; `shift` moves the time. */
const time = (shift = '') =>
  `strftime('%Y-%m-%dT%H:%M:%fZ', 'now'${shift && `, '${shift}'`})`;
const NOW = time();

// How long the row of an unregistered file is kept at least. A catalog sync
// lists the files to read when it starts and commits what it read when it
// ends. One that listed the file before it was unregistered can commit
// after a later sync has found nothing of the file left: were the row gone
// by then, the entities it brings back would count as coming from no
// registered file, the operator's, and be shown to everyone. Longer than
// any sync can run: the workflows that make one stop well within an hour.
const KEEP_UNREGISTERED_HOURS = 2;

/**
 * Condition on a `locations` row: it was unregistered long enough ago, and
 * nothing in the catalog descends from it any more. Only then can the row
 * go: while one of its entities is left, the row is what hides it.
 */
export const LEFT_THE_CATALOG = `removed_at < ${time(
  `-${KEEP_UNREGISTERED_HOURS} hours`,
)} AND lower(type || ':' || target) NOT IN (SELECT coalesce(${originOf(
  'remaining',
)}, '') FROM final_entities remaining)`;

/** SQL that unregisters a `locations` row: it stays, to hide its entities. */
export const UNREGISTER = `removed_at = ${NOW}`;

/**
 * SQL that registers an unregistered `locations` row again, for the account
 * `account` is SQL for: a new registration, with nothing of the old one.
 */
export const registerAgain = (account: string) =>
  `account = ${account}, removed_at = NULL, created_at = ${NOW}`;

/**
 * SQL for the account a user's registrations are filed under: their
 * organisation when they are in one, themself otherwise. `user` is SQL for
 * their lower-case ref, and appears twice in the result.
 */
export const filedUnder = (user: string) =>
  `coalesce((${ORGANISATION_ACCOUNT}${user}), ${user})`;
