/**
 * Tables and queries for organisations, their members, invitations and
 * logos. The Cloudflare Worker keeps the same tables in D1
 * (edge/migrations/0006_organisations.sql, 0007_accounts.sql).
 */

import { randomBytes } from 'crypto';
import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import {
  logoUrl,
  nameKey,
  refusals,
  type ApiError,
  type Invitation,
  type LogoKind,
  type Member,
  type Organisation,
  type OrganisationChanges,
  type OrganisationSummary,
  type ReceivedInvitation,
  type Role,
} from './rules';

interface OrganisationRow {
  slug: string;
  name: string;
  primary_color: string | null;
  theme_preset: string | null;
  /** What the organisation's catalog files are filed under. Never changes. */
  id: string | null;
  /** The name as it is compared: nameKey() of it. */
  name_key: string | null;
}

/** The tables that say which organisation a row belongs to by its slug. */
const BELONGINGS = [
  'organisation_members',
  'organisation_invitations',
  'organisation_logos',
];

/** 32 lower-case hex digits, as the Worker's migration makes them. */
const newId = () => randomBytes(16).toString('hex');

interface MemberRow {
  user_ref: string;
  slug: string;
  role: Role;
  added_at: string;
  added_by: string;
}

interface InvitationRow {
  slug: string;
  user_ref: string;
  role: Role;
  invited_at: string;
  invited_by: string;
}

interface LogoRow {
  slug: string;
  kind: LogoKind;
  content_type: string;
  bytes: Buffer;
  updated_at: string;
}

const ROLES = ['owner', 'member'];

export async function initializeTables(
  knex: Knex,
  logger: LoggerService,
): Promise<void> {
  if (!(await knex.schema.hasTable('organisations'))) {
    logger.info('Creating organisations table');
    await knex.schema.createTable('organisations', table => {
      table.string('slug').primary();
      table.string('name').notNullable();
      table.string('primary_color').nullable();
      table.string('theme_preset').nullable();
    });
  }

  if (!(await knex.schema.hasTable('organisation_members'))) {
    logger.info('Creating organisation_members table');
    await knex.schema.createTable('organisation_members', table => {
      // The primary key is what keeps a user in one organisation.
      table.string('user_ref').primary();
      table
        .string('slug')
        .notNullable()
        .index()
        .references('slug')
        .inTable('organisations')
        .onDelete('CASCADE');
      table.string('role').notNullable().checkIn(ROLES);
      // ISO strings: the same value on SQLite and Postgres.
      table.string('added_at').notNullable();
      table.string('added_by').notNullable();
    });
  }

  // People an owner has asked to join. A person may be invited by several
  // organisations, but only once by each.
  if (!(await knex.schema.hasTable('organisation_invitations'))) {
    logger.info('Creating organisation_invitations table');
    await knex.schema.createTable('organisation_invitations', table => {
      table
        .string('slug')
        .notNullable()
        .references('slug')
        .inTable('organisations')
        .onDelete('CASCADE');
      table.string('user_ref').notNullable().index();
      table.string('role').notNullable().checkIn(ROLES);
      table.string('invited_at').notNullable();
      table.string('invited_by').notNullable();
      table.primary(['slug', 'user_ref']);
    });
  }

  // Logo files, one row per organisation and kind. updated_at is also the
  // version in a logo's address, which browsers keep for a year.
  if (!(await knex.schema.hasTable('organisation_logos'))) {
    logger.info('Creating organisation_logos table');
    await knex.schema.createTable('organisation_logos', table => {
      table
        .string('slug')
        .notNullable()
        .references('slug')
        .inTable('organisations')
        .onDelete('CASCADE');
      table.string('kind').notNullable().checkIn(['full', 'icon']);
      table.string('content_type').notNullable();
      table.binary('bytes').notNullable();
      table.string('updated_at').notNullable();
      table.primary(['slug', 'kind']);
    });
  }

  // Added after the tables were first made, so also to tables that are
  // already there.
  if (!(await knex.schema.hasColumn('organisations', 'id'))) {
    logger.info('Adding id and name_key to the organisations table');
    await knex.transaction(async trx => {
      await trx.schema.alterTable('organisations', table => {
        table.string('id').nullable();
        // Text: a name written out in full can be longer than a string.
        table.text('name_key').nullable();
      });
      await fillIdsAndNameKeys(trx);
      await trx.schema.alterTable('organisations', table => {
        table.unique(['id'], { indexName: 'organisations_id' });
        table.unique(['name_key'], { indexName: 'organisations_name_key' });
      });
    });
  }
}

/**
 * Gives every organisation that was there before the columns an id and a
 * name key. Those that share a name keep it: the oldest, by when its first
 * member was added, has the key, and each later one is told apart by its
 * address until an owner renames it.
 */
async function fillIdsAndNameKeys(trx: Knex.Transaction): Promise<void> {
  const rows: { slug: string; name: string; since: string | null }[] =
    await trx('organisations as organisation')
      .leftJoin(
        'organisation_members as member',
        'member.slug',
        'organisation.slug',
      )
      .groupBy('organisation.slug', 'organisation.name')
      .select('organisation.slug', 'organisation.name')
      .min('member.added_at as since');
  // Sorted here: the databases differ in where they put a missing value.
  rows.sort(
    (a, b) =>
      (a.since ?? '').localeCompare(b.since ?? '') ||
      a.slug.localeCompare(b.slug),
  );
  const taken = new Set<string>();
  for (const { slug, name } of rows) {
    let key = nameKey(name.trim());
    while (taken.has(key)) {
      key = `${key} (${slug})`;
    }
    taken.add(key);
    await trx('organisations')
      .where('slug', slug)
      .update({ id: newId(), name_key: key });
  }
}

/** A unique key refused the row: the value is taken (Postgres, SQLite). */
function isDuplicate(error: unknown): boolean {
  if (!error || typeof error !== 'object' || !('code' in error)) {
    return false;
  }
  const code = String(error.code);
  return (
    code === '23505' ||
    code === 'SQLITE_CONSTRAINT_PRIMARYKEY' ||
    code === 'SQLITE_CONSTRAINT_UNIQUE'
  );
}

/** Runs one write, turning a taken key into `refusal`. */
async function writeOr(
  write: PromiseLike<unknown>,
  refusal: (error: unknown) => ApiError,
): Promise<void> {
  try {
    await write;
  } catch (error) {
    throw isDuplicate(error) ? refusal(error) : error;
  }
}

/**
 * What a write to `organisations` was refused for: its name or, failing
 * that, its address. Both databases name the key in the message: Postgres
 * as `organisations_name_key`, SQLite as `organisations.name_key`. The
 * message also quotes the statement, which names the column whatever was
 * refused, so the column's name alone says nothing. What the database
 * driver throws is read as it is given: it need not be an `Error` of the
 * code that catches it (it is not under jest, once another test file has
 * loaded the driver).
 */
const organisationTaken = (error: unknown) =>
  /organisations[._]name_key/.test(String(error))
    ? refusals.nameTaken()
    : refusals.slugTaken();

/**
 * Holds the organisation's row until the transaction ends, or refuses when
 * it is gone. The caller was checked a moment ago and the organisation may
 * have been deleted since; holding the row also makes the writes to one
 * organisation's members and invitations take turns.
 */
async function holdOrganisation(
  trx: Knex.Transaction,
  slug: string,
): Promise<OrganisationRow> {
  const organisation = await trx<OrganisationRow>('organisations')
    .where('slug', slug)
    .forUpdate()
    .first();
  if (!organisation) {
    throw refusals.noOrganisation();
  }
  return organisation;
}

export async function findOrganisation(
  knex: Knex,
  slug: string,
): Promise<Organisation | undefined> {
  const row = await knex<OrganisationRow>('organisations')
    .where('slug', slug)
    .first();
  if (!row) {
    return undefined;
  }
  // A logo's address is made from when it was uploaded, so it is not stored.
  const logos = await knex<LogoRow>('organisation_logos')
    .where('slug', slug)
    .select('kind', 'updated_at');
  const uploaded = (kind: LogoKind) =>
    logos.find(logo => logo.kind === kind)?.updated_at;
  return {
    slug: row.slug,
    name: row.name,
    logoFullUrl: logoUrl(slug, 'full', uploaded('full')),
    logoIconUrl: logoUrl(slug, 'icon', uploaded('icon')),
    primaryColor: row.primary_color,
    themePreset: row.theme_preset,
  };
}

/** The one organisation a user belongs to, if any. */
export async function findMembership(
  knex: Knex,
  userRef: string,
): Promise<{ slug: string; role: Role } | undefined> {
  const row = await knex<MemberRow>('organisation_members')
    .where('user_ref', userRef)
    .first();
  return row && { slug: row.slug, role: row.role };
}

/** Creates an organisation with `userRef` as its owner, or neither. */
export async function createOrganisation(
  knex: Knex,
  input: { slug: string; name: string },
  userRef: string,
): Promise<void> {
  await knex.transaction(async trx => {
    // Looked at first, so that when the address and the name are both
    // taken it is the address the caller is told about.
    if (await trx('organisations').where('slug', input.slug).first()) {
      throw refusals.slugTaken();
    }
    await writeOr(
      trx('organisations').insert({
        ...input,
        id: newId(),
        name_key: nameKey(input.name),
      }),
      organisationTaken,
    );
    await writeOr(
      trx('organisation_members').insert({
        user_ref: userRef,
        slug: input.slug,
        role: 'owner',
        added_at: new Date().toISOString(),
        added_by: userRef,
      }),
      refusals.alreadyMember,
    );
  });
}

/**
 * Changes the organisation, and answers with the address it then has. A
 * taken name is refused before a taken address.
 */
export async function updateOrganisation(
  knex: Knex,
  slug: string,
  changes: OrganisationChanges,
): Promise<string> {
  const { slug: address = slug, ...columns } = changes;
  const update: Partial<OrganisationRow> = {
    ...columns,
    ...(columns.name !== undefined && { name_key: nameKey(columns.name) }),
  };
  if (address === slug && !Object.keys(update).length) {
    return slug;
  }
  await knex.transaction(async trx => {
    const held = await holdOrganisation(trx, slug);
    if (Object.keys(update).length) {
      // Only the name can be taken here. Keeping its own name, in other
      // letter case too, is not.
      await writeOr(
        trx('organisations').where('slug', slug).update(update),
        refusals.nameTaken,
      );
    }
    if (address === slug) {
      return;
    }
    // The other tables refer to the address, so the row is not given a new
    // one: a second row is made under the new address, what belongs to the
    // organisation is moved to it, and the first row is removed. The id and
    // the name key are unique, so the first row lets go of them before the
    // second takes them.
    await trx('organisations')
      .where('slug', slug)
      .update({ id: null, name_key: null });
    await writeOr(
      trx('organisations').insert({ ...held, ...update, slug: address }),
      refusals.slugTaken,
    );
    for (const table of BELONGINGS) {
      await trx(table).where('slug', slug).update({ slug: address });
    }
    await trx('organisations').where('slug', slug).delete();
  });
  return address;
}

/**
 * Removes the organisation with its members, invitations and logos. They
 * are deleted by hand as well as by reference: SQLite follows references
 * only when asked. The organisation's row is held first, as every other
 * write to it does, so that two of them cannot wait on each other.
 *
 * Before anything is removed, `passOn` is given the organisation's id and
 * its longest-standing owner, who takes over what was filed under it. If
 * that fails the organisation stays.
 */
export async function deleteOrganisation(
  knex: Knex,
  slug: string,
  passOn: (id: string, owner: string) => Promise<void>,
): Promise<void> {
  await knex.transaction(async trx => {
    const { id } = await holdOrganisation(trx, slug);
    const owner = await trx<MemberRow>('organisation_members')
      .where({ slug, role: 'owner' })
      .orderBy([
        { column: 'added_at', order: 'asc' },
        { column: 'user_ref', order: 'asc' },
      ])
      .first();
    if (id && owner) {
      await passOn(id, owner.user_ref);
    }
    for (const table of [...BELONGINGS].reverse()) {
      await trx(table).where('slug', slug).delete();
    }
    await trx('organisations').where('slug', slug).delete();
  });
}

/** Every organisation on the portal, by name, for its administrators. */
export async function listOrganisations(
  knex: Knex,
): Promise<OrganisationSummary[]> {
  const organisations = await knex<OrganisationRow>('organisations')
    .orderBy('name_key')
    .select('slug', 'name');
  const members = await knex<MemberRow>('organisation_members')
    .orderBy([
      { column: 'added_at', order: 'asc' },
      { column: 'user_ref', order: 'asc' },
    ])
    .select('slug', 'user_ref', 'role');
  return organisations.map(({ slug, name }) => {
    const people = members.filter(member => member.slug === slug);
    return {
      slug,
      name,
      members: people.length,
      owners: people
        .filter(member => member.role === 'owner')
        .map(member => member.user_ref),
    };
  });
}

/** The id of the organisation a user belongs to, if they are in one. */
export async function findOrganisationId(
  knex: Knex,
  userRef: string,
): Promise<string | undefined> {
  const row: { id: string | null } | undefined = await knex(
    'organisation_members as member',
  )
    .join('organisations as organisation', 'organisation.slug', 'member.slug')
    .where('member.user_ref', userRef)
    .first('organisation.id');
  return row?.id ?? undefined;
}

export async function listMembers(knex: Knex, slug: string): Promise<Member[]> {
  const rows = await knex<MemberRow>('organisation_members')
    .where('slug', slug)
    .orderBy([
      { column: 'added_at', order: 'asc' },
      { column: 'user_ref', order: 'asc' },
    ]);
  return rows.map(row => ({
    userEntityRef: row.user_ref,
    role: row.role,
    addedAt: row.added_at,
    addedBy: row.added_by,
  }));
}

/** The people an organisation has invited who have not answered yet. */
export async function listInvitations(
  knex: Knex,
  slug: string,
): Promise<Invitation[]> {
  const rows = await knex<InvitationRow>('organisation_invitations')
    .where('slug', slug)
    .orderBy([
      { column: 'invited_at', order: 'asc' },
      { column: 'user_ref', order: 'asc' },
    ]);
  return rows.map(row => ({
    userEntityRef: row.user_ref,
    role: row.role,
    invitedAt: row.invited_at,
    invitedBy: row.invited_by,
  }));
}

/** The invitations a person has not answered yet, oldest first. */
export async function listReceivedInvitations(
  knex: Knex,
  userRef: string,
): Promise<ReceivedInvitation[]> {
  const rows = await knex('organisation_invitations as invitation')
    .join(
      'organisations as organisation',
      'organisation.slug',
      'invitation.slug',
    )
    .where('invitation.user_ref', userRef)
    .orderBy([
      { column: 'invitation.invited_at', order: 'asc' },
      { column: 'invitation.slug', order: 'asc' },
    ])
    .select<
      Array<
        Pick<InvitationRow, 'slug' | 'role' | 'invited_by'> & { name: string }
      >
    >(
      'invitation.slug',
      'organisation.name',
      'invitation.role',
      'invitation.invited_by',
    );
  return rows.map(row => ({
    slug: row.slug,
    name: row.name,
    role: row.role,
    invitedBy: row.invited_by,
  }));
}

/** Asks a person to join. They become a member only when they accept. */
export async function invite(
  knex: Knex,
  slug: string,
  person: { userRef: string; role: Role },
  invitedBy: string,
): Promise<void> {
  await knex.transaction(async trx => {
    await holdOrganisation(trx, slug);
    const member = await trx<MemberRow>('organisation_members')
      .where({ slug, user_ref: person.userRef })
      .first();
    if (member) {
      throw refusals.alreadyInThis();
    }
    await writeOr(
      trx('organisation_invitations').insert({
        slug,
        user_ref: person.userRef,
        role: person.role,
        invited_at: new Date().toISOString(),
        invited_by: invitedBy,
      }),
      refusals.alreadyInvited,
    );
  });
}

/** Takes up the invitation `userRef` holds: they become a member. */
export async function join(
  knex: Knex,
  slug: string,
  userRef: string,
): Promise<void> {
  await knex.transaction(async trx => {
    await holdOrganisation(trx, slug);
    const invitation = await trx<InvitationRow>('organisation_invitations')
      .where({ slug, user_ref: userRef })
      .first();
    if (!invitation) {
      throw refusals.notInvited();
    }
    await writeOr(
      trx('organisation_members').insert({
        user_ref: userRef,
        slug,
        role: invitation.role,
        added_at: new Date().toISOString(),
        added_by: invitation.invited_by,
      }),
      refusals.alreadyMember,
    );
    await trx('organisation_invitations')
      .where({ slug, user_ref: userRef })
      .delete();
  });
}

/**
 * Removes a person from an organisation: their membership, their
 * invitation, or both. Never the last owner.
 */
export async function remove(
  knex: Knex,
  slug: string,
  userRef: string,
): Promise<void> {
  await knex.transaction(async trx => {
    // Holding the organisation keeps two owners from removing each other
    // at once.
    await holdOrganisation(trx, slug);
    const member = await trx<MemberRow>('organisation_members')
      .where({ slug, user_ref: userRef })
      .first();
    if (member?.role === 'owner') {
      const owners = await trx<MemberRow>('organisation_members')
        .where({ slug, role: 'owner' })
        .select('user_ref');
      if (owners.length <= 1) {
        throw refusals.lastOwner();
      }
    }
    const removed =
      (await trx('organisation_members')
        .where({ slug, user_ref: userRef })
        .delete()) +
      (await trx('organisation_invitations')
        .where({ slug, user_ref: userRef })
        .delete());
    if (!removed) {
      throw refusals.noMember();
    }
  });
}

export async function saveLogo(
  knex: Knex,
  slug: string,
  kind: LogoKind,
  file: { type: string; bytes: Buffer },
): Promise<void> {
  await knex.transaction(async trx => {
    // Not for an organisation deleted since the caller was checked: the
    // logo would be left behind, served at its address.
    await holdOrganisation(trx, slug);
    await trx('organisation_logos')
      .insert({
        slug,
        kind,
        content_type: file.type,
        bytes: file.bytes,
        updated_at: new Date().toISOString(),
      })
      .onConflict(['slug', 'kind'])
      .merge();
  });
}

export async function deleteLogo(
  knex: Knex,
  slug: string,
  kind: LogoKind,
): Promise<void> {
  await knex('organisation_logos').where({ slug, kind }).delete();
}

export async function readLogo(
  knex: Knex,
  slug: string,
  kind: LogoKind,
): Promise<{ type: string; bytes: Buffer; updatedAt: string } | undefined> {
  const row = await knex<LogoRow>('organisation_logos')
    .where({ slug, kind })
    .first();
  return (
    row && {
      type: row.content_type,
      bytes: Buffer.from(row.bytes),
      updatedAt: row.updated_at,
    }
  );
}
