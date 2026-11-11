import { Hono, type Context } from 'hono';
import {
  ApiError,
  GUEST_USER,
  MAX_BODY_BYTES,
  MAX_LOGO_BYTES,
  checkLogo,
  logoHeaders,
  logoUrl,
  nameKey,
  readJson,
  readChanges,
  readLogoKind,
  readLogoType,
  readName,
  readRole,
  readSlug,
  readUserRef,
  refusals,
  type Invitation,
  type Member,
  type Organisation,
  type OrganisationSummary,
  type ReceivedInvitation,
  type Role,
} from '../../packages/backend/src/organisations/rules';
import { isPortalAdmin } from './admin';
import { handlePlainError } from './errors';
import type { AppEnv } from './types';

/**
 * Organisations: a name, an address (`/o/<slug>`) and a look, owned by the
 * people who created them. A user belongs to one organisation at most, so
 * signing in lands there. Same API as the Node backend's organisations
 * plugin, and the same rules: both read requests through rules.ts. Logos
 * are kept in D1 and served from here.
 */

// A logo's address is made from when it was uploaded, so it is not stored.
const SELECT_ORGANISATION = `SELECT slug, name, primary_color, theme_preset,
  (SELECT updated_at FROM organisation_logos l WHERE l.slug = o.slug AND kind = 'full') AS logo_full_at,
  (SELECT updated_at FROM organisation_logos l WHERE l.slug = o.slug AND kind = 'icon') AS logo_icon_at
  FROM organisations o`;
const SELECT_MEMBERS =
  'SELECT user_ref, role, added_at, added_by FROM organisation_members WHERE slug = ? ORDER BY added_at, user_ref';
const SELECT_INVITATIONS =
  'SELECT user_ref, role, invited_at, invited_by FROM organisation_invitations WHERE slug = ? ORDER BY invited_at, user_ref';

interface OrganisationRow {
  slug: string;
  name: string;
  primary_color: string | null;
  theme_preset: string | null;
  logo_full_at: string | null;
  logo_icon_at: string | null;
}

interface MemberRow {
  user_ref: string;
  role: Role;
  added_at: string;
  added_by: string;
}

interface InvitationRow {
  user_ref: string;
  role: Role;
  invited_at: string;
  invited_by: string;
}

const toOrganisation = (row: OrganisationRow): Organisation => ({
  slug: row.slug,
  name: row.name,
  logoFullUrl: logoUrl(row.slug, 'full', row.logo_full_at),
  logoIconUrl: logoUrl(row.slug, 'icon', row.logo_icon_at),
  primaryColor: row.primary_color,
  themePreset: row.theme_preset,
});

const toMember = (row: MemberRow): Member => ({
  userEntityRef: row.user_ref,
  role: row.role,
  addedAt: row.added_at,
  addedBy: row.added_by,
});

const toInvitation = (row: InvitationRow): Invitation => ({
  userEntityRef: row.user_ref,
  role: row.role,
  invitedAt: row.invited_at,
  invitedBy: row.invited_by,
});

const caller = (c: Context<AppEnv>) =>
  c.get('user').userEntityRef.toLowerCase();

const selectOrganisation = (c: Context<AppEnv>, slug: string) =>
  c.env.DB.prepare(`${SELECT_ORGANISATION} WHERE slug = ?`).bind(slug);

/**
 * The caller's role in the organisation, or null for someone who is not in
 * it. Says so when there is no such organisation, which is no secret.
 */
async function roleIn(c: Context<AppEnv>, slug: string): Promise<Role | null> {
  const found = await c.env.DB.prepare(
    'SELECT (SELECT role FROM organisation_members WHERE slug = ?1 AND user_ref = ?2) AS role FROM organisations WHERE slug = ?1',
  )
    .bind(slug, caller(c))
    .first<{ role: Role | null }>();
  if (!found) {
    throw refusals.noOrganisation();
  }
  return found.role;
}

/** Refuses callers who are not in the organisation. */
async function requireMember(c: Context<AppEnv>, slug: string): Promise<Role> {
  const role = await roleIn(c, slug);
  if (!role) {
    throw refusals.notMember();
  }
  return role;
}

/** Refuses callers who do not own the organisation. */
async function requireOwner(c: Context<AppEnv>, slug: string) {
  if ((await requireMember(c, slug)) !== 'owner') {
    throw refusals.notOwner();
  }
}

/**
 * The request body, read no further than `max` bytes: null when there is
 * more, whether or not the request said how long it is.
 */
async function readCapped(
  c: Context<AppEnv>,
  max: number,
): Promise<Uint8Array<ArrayBuffer> | null> {
  if (Number(c.req.header('content-length') ?? 0) > max) {
    return null;
  }
  const chunks: Uint8Array[] = [];
  let size = 0;
  const reader = c.req.raw.body?.getReader();
  for (;;) {
    const { done, value } = (await reader?.read()) ?? { done: true };
    if (done || !value) {
      break;
    }
    size += value.length;
    if (size > max) {
      await reader?.cancel();
      return null;
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let at = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, at);
    at += chunk.length;
  }
  return bytes;
}

/** The JSON object in the request body. */
async function readJsonBody(c: Context<AppEnv>) {
  const bytes = await readCapped(c, MAX_BODY_BYTES);
  if (!bytes) {
    throw refusals.bodyTooLarge();
  }
  return readJson(bytes);
}

/**
 * Runs `statements` as one transaction and responds with the organisation
 * as it is then.
 */
async function change(
  c: Context<AppEnv>,
  slug: string,
  statements: D1PreparedStatement[],
) {
  const results = await c.env.DB.batch<OrganisationRow>([
    ...statements,
    selectOrganisation(c, slug),
  ]);
  const row = results.at(-1)?.results[0];
  if (!row) {
    // Deleted by another owner since the caller was checked.
    throw refusals.noOrganisation();
  }
  return c.json(toOrganisation(row));
}

/** The members of an organisation and the people asked to join it. */
const selectPeople = (c: Context<AppEnv>, slug: string) => [
  c.env.DB.prepare(SELECT_MEMBERS).bind(slug),
  c.env.DB.prepare(SELECT_INVITATIONS).bind(slug),
];

const toPeople = (members: D1Result, invitations: D1Result) => ({
  members: (members.results as MemberRow[]).map(toMember),
  invitations: (invitations.results as InvitationRow[]).map(toInvitation),
});

const handleRefusal: Parameters<Hono<AppEnv>['onError']>[0] = (error, c) =>
  error instanceof ApiError
    ? c.json({ error: error.message }, error.status)
    : handlePlainError(error, c);

/**
 * Public: the sign-in page at an organisation's address shows its name and
 * logo before anyone has signed in.
 */
export const publicOrganisationRoutes = new Hono<AppEnv>();

publicOrganisationRoutes.onError(handleRefusal);

publicOrganisationRoutes.get('/:slug', async c => {
  const row = await selectOrganisation(
    c,
    c.req.param('slug'),
  ).first<OrganisationRow>();
  if (!row) {
    throw refusals.noOrganisation();
  }
  // Asked again on every page load, so a change or a deletion shows at once.
  return c.json(toOrganisation(row), 200, { 'cache-control': 'no-store' });
});

publicOrganisationRoutes.get('/:slug/logo/:kind', async c => {
  const logo = await c.env.DB.prepare(
    'SELECT content_type, bytes, updated_at FROM organisation_logos WHERE slug = ? AND kind = ?',
  )
    .bind(c.req.param('slug'), readLogoKind(c.req.param('kind')))
    // D1 returns a BLOB as an array of byte values.
    .first<{
      content_type: string;
      bytes: ArrayBuffer | number[];
      updated_at: string;
    }>();
  if (!logo) {
    throw refusals.noLogo();
  }
  // A version given twice is no version.
  const versions = c.req.queries('v');
  return new Response(new Uint8Array(logo.bytes), {
    headers: logoHeaders(
      logo.content_type,
      logo.updated_at,
      versions?.length === 1 ? versions[0] : undefined,
    ),
  });
});

export const organisationRoutes = new Hono<AppEnv>();

organisationRoutes.onError(handleRefusal);

// The caller's own organisation and the invitations waiting for them. The
// front end asks this after sign-in to know which address to show. With
// ?scope=portal, every organisation on the portal, for its administrators.
organisationRoutes.get('/', async c => {
  if (c.req.query('scope') === 'portal') {
    if (!(await isPortalAdmin(c))) {
      throw refusals.notPortalAdmin();
    }
    const { results } = await c.env.DB.prepare(
      `SELECT o.slug, o.name,
        (SELECT count(*) FROM organisation_members m WHERE m.slug = o.slug) AS members,
        (SELECT json_group_array(user_ref) FROM (SELECT user_ref FROM organisation_members m WHERE m.slug = o.slug AND m.role = 'owner' ORDER BY added_at, user_ref)) AS owners
        FROM organisations o ORDER BY o.name_key`,
    ).all<{ slug: string; name: string; members: number; owners: string }>();
    return c.json({
      organisations: results.map(
        (row): OrganisationSummary => ({
          ...row,
          owners: JSON.parse(row.owners),
        }),
      ),
    });
  }
  const userEntityRef = caller(c);
  const [mine, invited] = await c.env.DB.batch([
    c.env.DB.prepare(
      `SELECT o.*, m.role FROM (${SELECT_ORGANISATION}) o JOIN organisation_members m USING (slug) WHERE m.user_ref = ?`,
    ).bind(userEntityRef),
    c.env.DB.prepare(
      'SELECT i.slug, o.name, i.role, i.invited_by FROM organisation_invitations i JOIN organisations o USING (slug) WHERE i.user_ref = ? ORDER BY i.invited_at, i.slug',
    ).bind(userEntityRef),
  ]);
  const row = mine.results[0] as (OrganisationRow & { role: Role }) | undefined;
  return c.json({
    organisation: row ? toOrganisation(row) : null,
    role: row?.role ?? null,
    userEntityRef,
    // Guest sign-in is one shared account: an organisation made by it
    // would belong to everyone who uses it.
    canCreate: !row && userEntityRef !== GUEST_USER,
    invitations: (
      invited.results as (InvitationRow & { slug: string; name: string })[]
    ).map(
      (invitation): ReceivedInvitation => ({
        slug: invitation.slug,
        name: invitation.name,
        role: invitation.role,
        invitedBy: invitation.invited_by,
      }),
    ),
  });
});

/** Whether a failed write was refused because the key is already there. */
const isTaken = (error: unknown, key: string) =>
  error instanceof Error &&
  error.message.includes(`UNIQUE constraint failed: ${key}`);

organisationRoutes.post('/', async c => {
  const userEntityRef = caller(c);
  if (userEntityRef === GUEST_USER) {
    throw refusals.guest();
  }
  const body = await readJsonBody(c);
  const name = readName(body.name);
  const slug = readSlug(body.slug);
  // What the organisation's catalog files are filed under: 32 hex digits
  // that stay the same when its name or address changes.
  const id = Array.from(crypto.getRandomValues(new Uint8Array(16)), byte =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
  try {
    // One batch, so one transaction: no organisation without its owner.
    const results = await c.env.DB.batch<OrganisationRow>([
      c.env.DB.prepare(
        'INSERT INTO organisations (slug, name, id, name_key) VALUES (?, ?, ?, ?)',
      ).bind(slug, name, id, nameKey(name)),
      c.env.DB.prepare(
        "INSERT INTO organisation_members (user_ref, slug, role, added_at, added_by) VALUES (?1, ?2, 'owner', ?3, ?1)",
      ).bind(userEntityRef, slug, new Date().toISOString()),
      selectOrganisation(c, slug),
    ]);
    return c.json(toOrganisation(results[2].results[0]), 201);
  } catch (error) {
    if (isTaken(error, 'organisations.slug')) {
      throw refusals.slugTaken();
    }
    if (isTaken(error, 'organisations.name_key')) {
      // When the address is taken as well, that is what the caller is told,
      // as on the Node backend.
      const there = await c.env.DB.prepare(
        'SELECT 1 FROM organisations WHERE slug = ?',
      )
        .bind(slug)
        .first();
      throw there ? refusals.slugTaken() : refusals.nameTaken();
    }
    if (isTaken(error, 'organisation_members.user_ref')) {
      throw refusals.alreadyMember();
    }
    throw error;
  }
});

/**
 * Statements that give the organisation at `slug` the address `address`.
 * The other tables refer to the address, so the row is not given a new one:
 * a second row is made under the new address, what belongs to the
 * organisation is moved to it, and the first row is removed. The id and the
 * name key are unique, so the second row holds them marked (no id starts
 * with `~`, no name with a line break) until the first is gone. The first
 * statement makes the second row; it changes nothing when the organisation
 * is no longer there.
 */
const moveStatements = (c: Context<AppEnv>, slug: string, address: string) =>
  [
    "INSERT INTO organisations (slug, name, primary_color, theme_preset, id, name_key) SELECT ?2, name, primary_color, theme_preset, '~' || id, char(10) || name_key FROM organisations WHERE slug = ?1",
    'UPDATE organisation_members SET slug = ?2 WHERE slug = ?1',
    'UPDATE organisation_invitations SET slug = ?2 WHERE slug = ?1',
    'UPDATE organisation_logos SET slug = ?2 WHERE slug = ?1',
    // With ?2 named, so that every statement binds both.
    'DELETE FROM organisations WHERE slug = ?1 AND slug <> ?2',
    "UPDATE organisations SET id = CASE WHEN id LIKE '~%' THEN substr(id, 2) ELSE id END, name_key = CASE WHEN name_key LIKE char(10) || '%' THEN substr(name_key, 2) ELSE name_key END WHERE slug = ?2 AND slug <> ?1",
  ].map(sql => c.env.DB.prepare(sql).bind(slug, address));

organisationRoutes.patch('/:slug', async c => {
  const slug = c.req.param('slug');
  await requireOwner(c, slug);
  const { slug: address = slug, ...changes } = readChanges(
    await readJsonBody(c),
  );
  const set: Record<string, string | null> = {
    ...changes,
    ...(changes.name !== undefined && { name_key: nameKey(changes.name) }),
  };
  const columns = Object.keys(set);
  const statements = columns.length
    ? [
        // Column names come from rules.ts, never from the request.
        c.env.DB.prepare(
          `UPDATE organisations SET ${columns
            .map(column => `${column} = ?`)
            .join(', ')} WHERE slug = ?`,
        ).bind(...Object.values(set), slug),
      ]
    : [];
  // Where the statement that makes the row at the new address will be.
  const made = address === slug ? undefined : statements.length;
  if (made !== undefined) {
    statements.push(...moveStatements(c, slug, address));
  }
  try {
    // One batch, so one transaction. The name is changed first: a taken
    // name is refused before a taken address, as on the Node backend.
    const results = await c.env.DB.batch<OrganisationRow>([
      ...statements,
      selectOrganisation(c, address),
    ]);
    const row = results.at(-1)?.results[0];
    if (!row || (made !== undefined && !results[made].meta.changes)) {
      // Deleted by another owner since the caller was checked.
      throw refusals.noOrganisation();
    }
    return c.json(toOrganisation(row));
  } catch (error) {
    // Keeping its own name, in other letter case too, is not taken.
    if (isTaken(error, 'organisations.name_key')) {
      throw refusals.nameTaken();
    }
    if (isTaken(error, 'organisations.slug')) {
      throw refusals.slugTaken();
    }
    throw error;
  }
});

organisationRoutes.put('/:slug/logo/:kind', async c => {
  const slug = c.req.param('slug');
  await requireOwner(c, slug);
  const kind = readLogoKind(c.req.param('kind'));
  const bytes = await readCapped(c, MAX_LOGO_BYTES);
  if (!bytes) {
    throw refusals.logoTooLarge();
  }
  const type = readLogoType(c.req.header('content-type'));
  checkLogo(type, bytes);
  return change(c, slug, [
    // Only for an organisation that is still there: the caller was checked
    // a moment ago, and another owner may have deleted it since.
    c.env.DB.prepare(
      'INSERT INTO organisation_logos (slug, kind, content_type, bytes, updated_at) SELECT slug, ?2, ?3, ?4, ?5 FROM organisations WHERE slug = ?1 ON CONFLICT (slug, kind) DO UPDATE SET content_type = excluded.content_type, bytes = excluded.bytes, updated_at = excluded.updated_at',
    ).bind(slug, kind, type, bytes.buffer, new Date().toISOString()),
  ]);
});

organisationRoutes.delete('/:slug/logo/:kind', async c => {
  const slug = c.req.param('slug');
  await requireOwner(c, slug);
  const kind = readLogoKind(c.req.param('kind'));
  return change(c, slug, [
    c.env.DB.prepare(
      'DELETE FROM organisation_logos WHERE slug = ? AND kind = ?',
    ).bind(slug, kind),
  ]);
});

// An owner deletes their organisation; a portal administrator deletes any.
organisationRoutes.delete('/:slug', async c => {
  const slug = c.req.param('slug');
  const role = await roleIn(c, slug);
  if (role !== 'owner' && !(await isPortalAdmin(c))) {
    throw role ? refusals.notOwner() : refusals.notMember();
  }
  await c.env.DB.batch([
    // The catalog files registered under the organisation pass to its
    // longest-standing owner's own account.
    c.env.DB.prepare(
      "UPDATE locations SET account = (SELECT user_ref FROM organisation_members WHERE slug = ?1 AND role = 'owner' ORDER BY added_at, user_ref LIMIT 1) WHERE account = (SELECT 'organisation:' || id FROM organisations WHERE slug = ?1)",
    ).bind(slug),
    // Members, invitations and logos go with it: they reference it.
    c.env.DB.prepare('DELETE FROM organisations WHERE slug = ?').bind(slug),
  ]);
  return c.body(null, 204);
});

organisationRoutes.get('/:slug/members', async c => {
  const slug = c.req.param('slug');
  await requireMember(c, slug);
  const [members, invitations] = await c.env.DB.batch(selectPeople(c, slug));
  return c.json(toPeople(members, invitations));
});

// Asks a person to join. Nobody is put in an organisation by someone else:
// they join themselves, below.
organisationRoutes.post('/:slug/members', async c => {
  const slug = c.req.param('slug');
  await requireOwner(c, slug);
  const body = await readJsonBody(c);
  const entityRef = readUserRef(body.entityRef);
  const role = readRole(body.role);
  const [invited, members, invitations] = await c.env.DB.batch([
    // Only into an organisation that is still there, and only someone who
    // is not in it already. Whether they are in another is not looked at:
    // that is theirs to know.
    c.env.DB.prepare(
      'INSERT INTO organisation_invitations (slug, user_ref, role, invited_at, invited_by) SELECT slug, ?2, ?3, ?4, ?5 FROM organisations WHERE slug = ?1 AND NOT EXISTS (SELECT 1 FROM organisation_members WHERE slug = ?1 AND user_ref = ?2) ON CONFLICT (slug, user_ref) DO NOTHING',
    ).bind(slug, entityRef, role, new Date().toISOString(), caller(c)),
    ...selectPeople(c, slug),
  ]);
  const people = toPeople(members, invitations);
  if (!invited.meta.changes) {
    if (people.members.some(member => member.userEntityRef === entityRef)) {
      throw refusals.alreadyInThis();
    }
    throw people.invitations.some(
      invitation => invitation.userEntityRef === entityRef,
    )
      ? refusals.alreadyInvited()
      : refusals.noOrganisation();
  }
  return c.json(people);
});

// Takes up the caller's invitation.
organisationRoutes.post('/:slug/join', async c => {
  const slug = c.req.param('slug');
  await roleIn(c, slug);
  const userEntityRef = caller(c);
  try {
    // One batch, so one transaction: the invitation is used up only if the
    // caller got in. The member row comes from the invitation, so without
    // one nothing is written.
    const [joined, , stillThere] = await c.env.DB.batch([
      c.env.DB.prepare(
        'INSERT INTO organisation_members (user_ref, slug, role, added_at, added_by) SELECT user_ref, slug, role, ?3, invited_by FROM organisation_invitations WHERE slug = ?1 AND user_ref = ?2',
      ).bind(slug, userEntityRef, new Date().toISOString()),
      c.env.DB.prepare(
        'DELETE FROM organisation_invitations WHERE slug = ? AND user_ref = ?',
      ).bind(slug, userEntityRef),
      c.env.DB.prepare('SELECT 1 FROM organisations WHERE slug = ?').bind(slug),
    ]);
    if (!joined.meta.changes) {
      // Deleted since the caller was checked, or never invited.
      throw stillThere.results.length
        ? refusals.notInvited()
        : refusals.noOrganisation();
    }
  } catch (error) {
    throw isTaken(error, 'organisation_members.user_ref')
      ? refusals.alreadyMember()
      : error;
  }
  return change(c, slug, []);
});

// An owner removes a member or takes back an invitation. Anyone removes
// themself: that is how a member leaves and how an invitation is declined.
organisationRoutes.delete('/:slug/members/:entityRef', async c => {
  const slug = c.req.param('slug');
  const role = await roleIn(c, slug);
  // Who may is settled before what was asked for is looked at, so a caller
  // who is not allowed is told that whatever they sent.
  let entityRef: string | undefined;
  let invalid: unknown;
  try {
    entityRef = readUserRef(c.req.param('entityRef'));
  } catch (error) {
    invalid = error;
  }
  if (entityRef !== caller(c)) {
    if (!role) {
      throw refusals.notMember();
    }
    if (role !== 'owner') {
      throw refusals.notOwner();
    }
  }
  if (entityRef === undefined) {
    throw invalid;
  }
  // The count is part of the delete, so two removals at once cannot leave
  // an organisation that nobody can change.
  const [member, invitation, left, stillThere] = await c.env.DB.batch([
    c.env.DB.prepare(
      "DELETE FROM organisation_members WHERE slug = ?1 AND user_ref = ?2 AND (role <> 'owner' OR (SELECT count(*) FROM organisation_members WHERE slug = ?1 AND role = 'owner') > 1)",
    ).bind(slug, entityRef),
    c.env.DB.prepare(
      'DELETE FROM organisation_invitations WHERE slug = ? AND user_ref = ?',
    ).bind(slug, entityRef),
    c.env.DB.prepare(
      'SELECT 1 FROM organisation_members WHERE slug = ? AND user_ref = ?',
    ).bind(slug, entityRef),
    c.env.DB.prepare('SELECT 1 FROM organisations WHERE slug = ?').bind(slug),
  ]);
  if (left.results.length) {
    // Still there, so the delete was refused: the last owner.
    throw refusals.lastOwner();
  }
  if (!member.meta.changes && !invitation.meta.changes) {
    // Deleted since the caller was checked, or nobody by that name.
    throw stillThere.results.length
      ? refusals.noMember()
      : refusals.noOrganisation();
  }
  return c.body(null, 204);
});

// Whatever else is asked for under this address does not exist.
organisationRoutes.all('*', () => {
  throw new ApiError(404, 'There is no such call');
});
