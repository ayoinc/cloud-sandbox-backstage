/**
 * What the organisations API accepts and how it says no. The Node backend
 * and the Cloudflare Worker (edge/src/organisations.ts) both read requests
 * through this file, so the two cannot drift apart. It imports nothing: the
 * Worker bundles it as it is.
 */

/** A refusal the caller is told about: `{ error: message }` with the status. */
export class ApiError extends Error {
  constructor(readonly status: 400 | 403 | 404 | 409 | 413, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

export type Role = 'owner' | 'member';
export type LogoKind = 'full' | 'icon';

/** An organisation as every route returns it. */
export interface Organisation {
  slug: string;
  name: string;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
}

export interface Member {
  userEntityRef: string;
  role: Role;
  addedAt: string;
  addedBy: string;
}

/** Someone an owner has asked to join, who has not answered yet. */
export interface Invitation {
  userEntityRef: string;
  role: Role;
  invitedAt: string;
  invitedBy: string;
}

/** An invitation as the person invited sees it. */
export interface ReceivedInvitation {
  slug: string;
  name: string;
  role: Role;
  invitedBy: string;
}

/** An organisation as a portal administrator's list shows it. */
export interface OrganisationSummary {
  slug: string;
  name: string;
  /** How many people are in it. */
  members: number;
  /** Its owners' user refs, longest-standing first. */
  owners: string[];
}

/**
 * What a PATCH may change: the name and the look by column, and `slug`, the
 * address, which the other tables refer to and so is moved, not updated.
 */
export type OrganisationChanges = Partial<
  Record<'primary_color' | 'theme_preset', string | null>
> & { name?: string; slug?: string };

/** The account guest sign-in gives to everyone who uses it. */
export const GUEST_USER = 'user:development/guest';

const SLUG = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
const MAX_NAME_LENGTH = 80;
const USER_REF = /^user:[^/:\s]+\/[^/:\s]+$/;
/** What a Google account's name may hold besides the parts that are escaped. */
const PLAIN_IN_USER_NAME = /^[a-z0-9.-]$/;
/** A mail domain: two or more labels with dots between, as `example.com`. */
const MAIL_DOMAIN = /^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/;
/** The longest name a catalog entity can have. */
const MAX_USER_NAME_LENGTH = 63;
/** Longer than any real name, shorter than a database text column. */
const MAX_USER_REF_LENGTH = 200;

/** The look: field name, column, and what a value must look like. */
const LOOK_FIELDS = [
  {
    name: 'primaryColor',
    column: 'primary_color',
    pattern: /^#[0-9a-f]{6}$/i,
    message: 'The colour must be # and six hex digits, such as #1a2b3c',
  },
  {
    name: 'themePreset',
    column: 'theme_preset',
    pattern: /^[a-z][a-z0-9-]{0,39}$/,
    message: 'The theme must be the name of a built-in theme, such as forest',
  },
] as const;

/** A JSON body larger than any these routes take. */
export const MAX_BODY_BYTES = 16 * 1024;
/** Larger than any reasonable logo, small enough for one database value. */
export const MAX_LOGO_BYTES = 1024 * 1024;
export const LOGO_TYPES = [
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
  'image/gif',
];

/** Sent with every logo. */
const LOGO_HEADERS = {
  'x-content-type-options': 'nosniff',
  // A logo is for an <img>. Opened on its own it is saved, not shown: an
  // SVG is a document, and anyone may upload one.
  'content-disposition': 'attachment',
  // And if a browser shows it all the same, it runs no script and loads
  // nothing, with this origin's cookies in reach.
  'content-security-policy':
    "default-src 'none'; style-src 'unsafe-inline'; sandbox",
};

/**
 * The headers a logo is served with. Browsers may keep it for a year when
 * the address names the version being served (`asked`, the `v` in the
 * address); any other address is checked again each time, so a replaced or
 * removed logo does not linger.
 */
export const logoHeaders = (
  type: string,
  uploadedAt: string,
  asked: string | undefined,
) => ({
  'content-type': type,
  'cache-control':
    asked === String(Date.parse(uploadedAt))
      ? 'public, max-age=31536000, immutable'
      : 'no-cache',
  ...LOGO_HEADERS,
});

export const refusals = {
  noOrganisation: () => new ApiError(404, 'No such organisation'),
  noLogo: () => new ApiError(404, 'No such logo'),
  noMember: () => new ApiError(404, 'No such member'),
  notMember: () =>
    new ApiError(403, 'You are not a member of this organisation'),
  notOwner: () =>
    new ApiError(403, 'Only an owner can change this organisation'),
  notPortalAdmin: () =>
    new ApiError(403, 'Only a portal administrator can list organisations'),
  guest: () =>
    new ApiError(
      403,
      'The guest account cannot create an organisation. Sign in with your own account',
    ),
  slugTaken: () => new ApiError(409, 'That address is taken'),
  nameTaken: () =>
    new ApiError(
      409,
      'Another organisation on this portal already has that name. Choose a different one',
    ),
  alreadyMember: () =>
    new ApiError(
      409,
      'You already belong to an organisation. Leave it before you create or join another',
    ),
  alreadyInThis: () =>
    new ApiError(409, 'That person is already a member of this organisation'),
  alreadyInvited: () =>
    new ApiError(409, 'That person has already been invited'),
  notInvited: () =>
    new ApiError(404, 'You have not been invited to this organisation'),
  lastOwner: () =>
    new ApiError(
      409,
      'You are the only owner. Invite another owner and wait until they have joined, or delete the organisation',
    ),
  badBody: () => new ApiError(400, 'The request body must be a JSON object'),
  bodyTooLarge: () =>
    new ApiError(413, 'That request is too large: at most 16 KB'),
  logoType: () =>
    new ApiError(400, 'A logo must be a PNG, JPEG, SVG, WebP or GIF file'),
  logoEmpty: () =>
    new ApiError(400, 'That file is empty. Choose an image file'),
  logoTooLarge: () =>
    new ApiError(413, 'That logo is too large. A logo can be up to 1 MB'),
};

/**
 * The JSON object a request body holds. `bytes` is the body as it was sent,
 * already known to be no longer than MAX_BODY_BYTES; an empty one is not an
 * object.
 */
export function readJson(bytes: Uint8Array): Record<string, unknown> {
  let value: unknown;
  try {
    value = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    throw refusals.badBody();
  }
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw refusals.badBody();
  }
  return { ...value };
}

/**
 * An organisation's name: 1 to 80 characters on one line, once trimmed,
 * with something in it to read.
 */
export function readName(value: unknown): string {
  const name = typeof value === 'string' ? value.trim() : '';
  if (
    // Counted as people count them: an emoji is one character.
    [...name].length > MAX_NAME_LENGTH ||
    // At least one letter or digit: not only spaces and marks nobody sees.
    !/[\p{L}\p{N}]/u.test(name) ||
    // No line breaks, other control characters, or characters that turn
    // the direction of the text around it.
    /[\p{Cc}\p{Zl}\p{Zp}\u061c\u200e\u200f\u202a-\u202e\u2066-\u2069]/u.test(
      name,
    )
  ) {
    throw new ApiError(
      400,
      `The organisation name must be 1 to ${MAX_NAME_LENGTH} characters on one line, with a letter or digit in it`,
    );
  }
  return name;
}

/** The slug a new organisation asks for. */
export function readSlug(value: unknown): string {
  if (typeof value !== 'string' || !SLUG.test(value)) {
    throw new ApiError(
      400,
      'The address must be 3 to 40 lower-case letters, digits and dashes, starting and ending with a letter or digit',
    );
  }
  return value;
}

/**
 * The changes a PATCH asks for. A field that was not sent is left out; null
 * or an empty string clears the colour or the theme.
 */
export function readChanges(
  body: Record<string, unknown>,
): OrganisationChanges {
  const changes: OrganisationChanges = {};
  if (body.name !== undefined) {
    changes.name = readName(body.name);
  }
  if (body.slug !== undefined) {
    changes.slug = readSlug(body.slug);
  }
  for (const { name, column, pattern, message } of LOOK_FIELDS) {
    const value = body[name];
    if (value === undefined) {
      continue;
    }
    if (value === null) {
      changes[column] = null;
      continue;
    }
    const text = typeof value === 'string' ? value.trim() : undefined;
    if (text === undefined || (text !== '' && !pattern.test(text))) {
      throw new ApiError(400, message);
    }
    changes[column] = text || null;
  }
  return changes;
}

/**
 * The name as it is compared: no two organisations on a portal have names
 * that differ only in case, in spacing or in how a character is written.
 * `name` is one that readName returned.
 */
export const nameKey = (name: string) =>
  name.normalize('NFKC').toLowerCase().replace(/\s+/gu, ' ');

/**
 * The user name of someone who signs in with Google, from their email
 * address: `<local part>_<domain>` in lower case, so `jane@example.com` is
 * `jane_example.com`. A character of the local part that is not a letter, a
 * digit, a dot or a dash is written `_<its code point in hex>_`, so no two
 * addresses share a name: the domain is what follows the last `_`.
 *
 * The domain must have a dot in it, so a Google name always holds a `.`. A
 * GitHub login never does (it may hold `_`: the logins of managed accounts
 * end `_<short code>`), so no Google name is also a GitHub one.
 *
 * Undefined for what is not an email address at such a domain, and for one
 * whose name would be longer than an entity name may be or would not start
 * with a letter or digit.
 */
export function googleUserName(email: string): string | undefined {
  const address = email.trim().toLowerCase();
  const at = address.lastIndexOf('@');
  const local = address.slice(0, Math.max(at, 0));
  const domain = address.slice(at + 1);
  if (!local || !MAIL_DOMAIN.test(domain)) {
    return undefined;
  }
  const name = `${Array.from(local, character =>
    PLAIN_IN_USER_NAME.test(character)
      ? character
      : `_${character.codePointAt(0)!.toString(16)}_`,
  ).join('')}_${domain}`;
  return name.length <= MAX_USER_NAME_LENGTH && /^[a-z0-9]/.test(name)
    ? name
    : undefined;
}

/**
 * A person, in lower case, from a bare name (`jane`), a full reference
 * (`user:default/jane`) or a full email address, which is the person who
 * signs in with Google under it. Groups and the guest account are refused:
 * neither is one person.
 */
export function readUserRef(value: unknown): string {
  let text = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (text.includes('@') && !text.includes(':')) {
    // An address no name can be made from is nobody.
    text = googleUserName(text) ?? '';
  }
  const ref = text && !text.includes(':') ? `user:default/${text}` : text;
  if (
    !USER_REF.test(ref) ||
    ref.length > MAX_USER_REF_LENGTH ||
    ref === GUEST_USER
  ) {
    throw new ApiError(
      400,
      "Enter a person's user name, such as jane, or their full email address. Groups and the guest account cannot be invited",
    );
  }
  return ref;
}

/** The role a new member is given: `member` unless `owner` is asked for. */
export function readRole(value: unknown): Role {
  if (value === undefined) {
    return 'member';
  }
  if (value !== 'member' && value !== 'owner') {
    throw new ApiError(400, 'The role must be member or owner');
  }
  return value;
}

/** The logo kind in an address, or a 404: there are only two. */
export function readLogoKind(value: string): LogoKind {
  if (value !== 'full' && value !== 'icon') {
    throw refusals.noLogo();
  }
  return value;
}

/** The type a logo is sent as: the Content-Type header without parameters. */
export const readLogoType = (header: string | undefined) =>
  (header ?? '').split(';')[0].trim().toLowerCase();

const startsWith = (bytes: Uint8Array, signature: number[], at = 0) =>
  signature.every((byte, index) => bytes[at + index] === byte);

/** What the first bytes of a file say it is, for the types a logo may be. */
function sniff(bytes: Uint8Array): string | undefined {
  if (startsWith(bytes, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return 'image/png';
  }
  if (startsWith(bytes, [0xff, 0xd8, 0xff])) {
    return 'image/jpeg';
  }
  if (startsWith(bytes, [0x47, 0x49, 0x46, 0x38])) {
    return 'image/gif';
  }
  if (
    startsWith(bytes, [0x52, 0x49, 0x46, 0x46]) &&
    startsWith(bytes, [0x57, 0x45, 0x42, 0x50], 8)
  ) {
    return 'image/webp';
  }
  // An SVG is text with an <svg element in it.
  return /<svg[\s>]/i.test(new TextDecoder().decode(bytes))
    ? 'image/svg+xml'
    : undefined;
}

/**
 * Refuses a logo that is too large, of a type that is not taken, or whose
 * bytes are not what `type` says: the file is served to anyone who asks.
 */
export function checkLogo(type: string, bytes: Uint8Array): void {
  if (!LOGO_TYPES.includes(type)) {
    throw refusals.logoType();
  }
  if (bytes.length === 0) {
    throw refusals.logoEmpty();
  }
  if (bytes.length > MAX_LOGO_BYTES) {
    throw refusals.logoTooLarge();
  }
  if (sniff(bytes) !== type) {
    throw refusals.logoType();
  }
}

/**
 * Where a logo is served from, given when it was last uploaded (an ISO
 * time), or null without one. Relative, so it works on whatever address the
 * portal has. Browsers keep a logo for a year; the version makes a new one
 * show.
 */
export const logoUrl = (
  slug: string,
  kind: LogoKind,
  uploadedAt: string | null | undefined,
) =>
  uploadedAt
    ? `/api/organisations/${slug}/logo/${kind}?v=${Date.parse(uploadedAt)}`
    : null;
