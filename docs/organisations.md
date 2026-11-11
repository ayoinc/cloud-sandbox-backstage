# Organisations

The portal, a [Backstage](https://backstage.io) app, has no name, logo or
colours of its own. A signed-in user can create an **organisation**: a name,
an address (`/o/<slug>`, where the slug is the short name its creator picks,
such as `acme`) and a **look** (two logos, a theme and a primary colour). The
portal shows the name and the look only at that address.

The portal runs in two ways, and organisations work the same in both:
**serverless**, the build in `edge/`, where a Worker serves the API and keeps
its data in D1 (an SQL database), or on a **VM or in containers**, where the
Backstage Node backend does. This page calls the first "the Worker";
[Accounts](accounts.md), which says what each account can see, calls it the
serverless host.

## What a user sees

| Where                                | Signed out                               | Signed in                                                                                                                                                                                             |
| ------------------------------------ | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The portal root, `/`                 | Plain sign-in page: no name, no logo     | A member of an organisation is redirected to its address. Anyone else stays at the portal root, and is taken to **Settings > Organisation** when there is something to do there (see below)           |
| An organisation's address, `/o/acme` | Sign-in page with Acme's name and look   | A member of Acme sees the portal with Acme's name and look. Anyone else is redirected to the same page in their own organisation or, if they have none, without the prefix (`/o/acme/x` becomes `/x`) |
| An address nobody has, `/o/nope/x`   | Plain sign-in page, still at `/o/nope/x` | Redirected to the same page in their own organisation (`/o/acme/x`), or without the prefix (`/x`)                                                                                                     |

- A user belongs to at most **one** organisation. After sign-in the app
  redirects a member to that organisation's address, whichever address they
  signed in at. The screens say members "land" there.
- Nobody is put in an organisation by someone else. An owner invites a user;
  the user joins, or declines, from their own **Settings > Organisation** tab.
  A user who is already in an organisation sees the invitation there too, but
  can only decline it until they leave their own. The owner who invited them
  is not told whether they are in one.
- A user who arrives at the portal root or at their organisation's front page
  with an invitation to answer, or with no organisation (and not as the guest
  account), is taken to **Settings > Organisation**. This happens once per
  browser for the form that creates an organisation and once for each
  invitation, declined or not. A link to any other page is left alone. The
  tab is always there.
- **Sign out**, and the idle time-out (one hour without activity), go to the
  front page of the address the user is at. A member therefore sees their
  organisation's sign-in page afterwards.
- Guest sign-in, where it is enabled, is one account (`user:development/guest`)
  shared by everyone who uses it. The API refuses to create an organisation
  for it or to invite it.

## What an organisation is

| Part    | Contents                                      | Constraints                                                                                                                                                                                                       |
| ------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Name    | Text                                          | 1 to 80 characters on one line. An owner can change it. No two organisations on a portal have the same name: names that differ only in letter case, in spacing or in how a character is written count as the same |
| Address | `/o/<slug>`                                   | The slug is 3 to 40 lower-case letters, digits and dashes, starting and ending with a letter or digit. It is unique. An owner can change it; the old address stops working at once (see below)                    |
| Look    | Full logo, icon logo, theme, primary colour   | Each is optional. Without a full logo the sidebar shows the portal's plain mark and the name; without a theme, `neutral`                                                                                          |
| Members | Users, each with the role `owner` or `member` | The creator is the first owner. The API refuses to remove the last owner                                                                                                                                          |

The full logo is shown in the open sidebar and on the sign-in page, the icon
logo in the collapsed sidebar. A theme is one of the built-in presets:
`neutral`, `harbour`, `forest`, `plum`, `ember`, `civic`, `baseline`. The
primary colour replaces the theme's colour for buttons and links. The screens
call the look "logo and theme".

| Role     | May                                                                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `owner`  | Everything a member may; change the name, the address and the look; invite and remove people, and take back invitations; delete the organisation |
| `member` | See who is in the organisation and who has been invited; leave                                                                                   |

To hand an organisation over, an owner invites the new owner with the role
`owner`, waits until they have joined, then leaves. If the new owner is
already a member, remove them first and invite them again as `owner`: no call
changes a role. If they belong to another organisation they have to leave it
before they can join.

### Changing the address

An owner changes the address in **Settings > Organisation**. The screen warns
before it does, and then loads the same page at the new address.

- The old address stops working at once. Nothing redirects from it: a
  signed-out visitor gets the plain sign-in page there, and a signed-in member
  is redirected to the new address like anyone at an address that is not
  theirs.
- The old address is free at once, so another organisation can take it. Links
  and bookmarks to it then lead there, and a signed-out visitor who follows
  one sees that other organisation's name and logo on the sign-in page. Tell
  your members the new address before you change it.
- Members, invitations, logos and what the organisation registered in the
  catalog stay with it. The logos' URLs change with the address.

## Where it is managed

| Page                        | Address                           | Who                                                                                                                      |
| --------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Create an organisation      | `/settings/organisation`          | A signed-in user who has none, except the guest account                                                                  |
| Answer an invitation        | `/settings/organisation`          | The user invited                                                                                                         |
| Name, address, theme, logos | `/o/<slug>/settings/organisation` | Owners. A name or an address that is taken is said beside the field. A member is told that only an owner can change them |
| Members and invitations     | `/o/<slug>/settings/organisation` | Owners invite and remove; every member sees the list and can leave                                                       |
| Portal administrators       | `/admin/administrators`           | Portal administrators. Nothing links to it: open the address                                                             |
| Every organisation          | `/admin/administrators`           | Portal administrators: name, address, number of members and owners of each, and **Remove**                               |

## What is separated

What is kept apart is filed under an **account**: an organisation or, for
someone who is in none, the person. A catalog file registered through the
portal (catalog import, or a template run that registers what it made)
belongs to the account of whoever registered it, and its entities, with their
documentation, search results and the rest that follows from them, are shown
to that account only. What the operator put in the portal's own configuration
is shown to everyone who can sign in. A template run is shown to the person
who started it.

- An organisation's account is an id that never changes and that the API
  never returns, so what it registered stays with it through a change of name
  or address.
- Someone who joins an organisation sees what it registered as well as what
  they registered themself. What they register from then on is the
  organisation's.
- When an organisation is deleted, what it registered passes to its
  longest-standing owner (the one added first; by user reference if two were
  added at the same moment), as their own.
- Entity names are portal-wide: a second account that registers an entity
  under a name already in use gets a processing conflict.

Portal administrators are one portal-wide list, managed at
`/admin/administrators`. The `PORTAL_ADMINS` setting (an environment variable
on the Node backend, a variable of the Worker) names administrators as well:
a comma-separated list of user names (`jane`, or `jane_example.com` for
someone who signs in with Google) or full references
(`group:default/platform`). If it is empty and the list is empty, the first
person to sign in with their own account becomes a portal administrator,
whoever they are: set `PORTAL_ADMINS` before the portal can be reached by
people you do not know.

Over organisations a portal administrator has two rights: to list them all,
with each one's name, address, owners and number of members, and to remove
any of them. They cannot read the other members or the invitations, change
the name, address or look, or see what it registered.

A group reference can be on the list. A person then has the role only when
their sign-in token names that group, and the sign-ins the portal ships with
name only the person. On a VM or in containers a group on the list counts
only for listing and removing organisations. List people.

### What is public

An organisation's name and look are public: the sign-in page shows them
before anyone has signed in, and anyone can fetch the logos. Its members and
invitations are not.

### Not done

- Transferring an organisation in one step, or changing a member's role.
- Redirecting from an address an organisation has left or been deleted from.
  The address is free at once, so old links and bookmarks then lead to whoever
  takes it next.
- Limits on how many people an owner may invite.

## How the address works

The front end is one build, served for every path. Before it starts it reads
the page's own path (`packages/app/src/App.tsx`, `loadConfig`):

1. If the path begins `/o/<slug>`, the app's base path becomes `/o/<slug>`, so
   every route and link stays under it, and the app asks the backend for that
   organisation (`GET /api/organisations/<slug>`, no sign-in needed).
2. On 200 the app applies the organisation's name and look before it draws
   anything, and uses the name as the browser tab's title. On any other
   answer, or none within four seconds, it starts with no name and no look.
3. For any other path the app starts at its configured base path with no
   name and no look.

After sign-in, `OrganisationGate`
(`packages/app/src/components/organisation/OrganisationGate.tsx`) asks which
organisation the user belongs to (`GET /api/organisations`). If the slug in
the address differs, it redirects the browser to the same page, query and
fragment under the user's organisation, or outside any organisation if the
user has none. If that call fails, the user stays where they are.

A redirect always stays on the portal: `organisationPath`
(`packages/brand/src/identity/brandIdentity.ts`) returns a path with a single
leading slash, whatever the address contained. An address is an
organisation's only when it is spelt as a slug is: `/o/Acme` is an ordinary
page that does not exist.

The gate asks once, when the app has loaded. It remembers in the browser
(`localStorage`, key `organisation-shown`) the user, and what it has already
taken them to **Settings > Organisation** for. Nothing else about
organisations is stored in the browser.

API calls, static files and sign-in callbacks stay at the portal root
(`/api/...`, `/static/...`); only pages move under `/o/<slug>`. The callback
addresses registered with GitHub and Google therefore do not change.

## API

Base path `/api/organisations`. The Worker
(`edge/src/organisations.ts`) and the Node backend
(`packages/backend/src/organisations/`) serve it. Both read every request
through one file, `packages/backend/src/organisations/rules.ts`, which holds
the validation rules, the refusals and their messages.

### The organisation object

```json
{
  "slug": "acme",
  "name": "Acme Ltd",
  "logoFullUrl": "/api/organisations/acme/logo/full?v=1731312000000",
  "logoIconUrl": null,
  "primaryColor": "#1a2b3c",
  "themePreset": "forest"
}
```

Logo URLs are paths, to be read against the backend's origin; they assume the
backend's address has no path prefix of its own. They are not stored: `v` is
the time of the upload. A logo fetched at the URL with its current `v` may be
cached for a year; at any other URL the browser checks again each time. A
logo is served as a download, for use in an `<img>`: opened on its own it is
saved, not shown.

### Calls

"Signed in" means the request carries the Backstage user token as
`Authorization: Bearer <token>`, which the app's `fetchApi` adds. "Member"
includes owners.

| Call                               | Who                              | Body                                                 | Answer                                                                                                                                                      |
| ---------------------------------- | -------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /:slug`                       | Anyone, signed in or not         | -                                                    | 200 with the organisation, never cached; 404                                                                                                                |
| `GET /:slug/logo/:kind`            | Anyone, signed in or not         | -                                                    | 200 with the image; 404. `kind` is `full` or `icon`                                                                                                         |
| `GET /`                            | Any signed-in user               | -                                                    | 200 with `{ organisation, role, userEntityRef, canCreate, invitations }`                                                                                    |
| `GET /?scope=portal`               | Portal administrator             | -                                                    | 200 with `{ organisations }`, every organisation on the portal. 403 for anyone else                                                                         |
| `POST /`                           | Any signed-in user               | `{ "name", "slug" }`                                 | 201 with the organisation, the caller its owner. 403 for the guest account. 409 if the slug or the name is taken, or the caller already has an organisation |
| `PATCH /:slug`                     | Owner                            | Any of `name`, `slug`, `primaryColor`, `themePreset` | 200 with the organisation, at its new address if `slug` changed it. 409 if the name or the slug is taken                                                    |
| `PUT /:slug/logo/:kind`            | Owner                            | The image itself; `Content-Type` is its type         | 200 with the organisation. 413 if larger than 1 MB (1,048,576 bytes)                                                                                        |
| `DELETE /:slug/logo/:kind`         | Owner                            | -                                                    | 200 with the organisation                                                                                                                                   |
| `DELETE /:slug`                    | Owner, or a portal administrator | -                                                    | 204. Members, invitations and logos go with it                                                                                                              |
| `GET /:slug/members`               | Member                           | -                                                    | 200 with `{ members, invitations }`                                                                                                                         |
| `POST /:slug/members`              | Owner                            | `{ "entityRef", "role" }`                            | 200 with `{ members, invitations }`. 409 if that user is a member of this organisation or already invited to it                                             |
| `POST /:slug/join`                 | The user invited                 | -                                                    | 200 with the organisation. 404 without an invitation. 409 if the caller already has an organisation                                                         |
| `DELETE /:slug/members/:entityRef` | Owner; or any user, for themself | -                                                    | 204. 409 if it would remove the last owner. 404 if that user is neither a member nor invited                                                                |

- In the answer to `GET /`, `organisation` and `role` are `null` when the
  caller has no organisation. `canCreate` is `true` when the caller has none
  and is not the guest account. `invitations` lists the caller's own, each
  `{ slug, name, role, invitedBy }`.
- `GET /?scope=portal`: each item is `{ slug, name, members, owners }`, where
  `members` is a count and `owners` the owners' user references,
  longest-standing first. The list is in order of name. Without `scope=portal`
  a portal administrator gets the same answer as anyone.
- `PATCH`: a field that is not sent stays as it is; `null` or `""` clears the
  colour or the theme. `primaryColor` is `#rrggbb`. `themePreset` is the name
  of a theme; a name the app does not know is stored and shown as `neutral`.
- `PATCH` with `slug` moves the organisation: the answer is the organisation
  at the new slug, and every call at the old one then answers 404. Sending the
  slug it already has changes nothing. When both the name and the slug sent
  are taken, the answer is about the name, and nothing is changed.
- A name is taken when another organisation's name is the same once both are
  in lower case with runs of spaces read as one space (Unicode NFKC). An
  organisation can always change the letter case or spacing of its own name.
  In `POST /`, when both are taken, the answer is about the slug.
- `PUT` logo: PNG, JPEG, SVG, WebP or GIF. The bytes must be what the type
  says.
- `POST /:slug/members` invites; it adds nobody. Whether the user is in
  another organisation is neither checked nor revealed. A user can be invited
  before they have ever signed in.
- `DELETE /:slug/members/:entityRef` removes a member or an invitation. For
  themself it is how a member leaves and how a user declines.
- A member is `{ userEntityRef, role, addedAt, addedBy }`; `addedBy` is who
  invited them, or themself for the creator. An invitation is
  `{ userEntityRef, role, invitedAt, invitedBy }`.

### User references

Users are named by Backstage
[entity references](https://backstage.io/docs/features/software-catalog/references)
in lower case, such as `user:default/jane`, at most 200 characters.
`entityRef` in a request and `userEntityRef` in an answer are the same thing.
The `entityRef` of a request, in a body or in a path, may also be a bare
name, or a full email address: `jane` means `user:default/jane`, and
`jane@example.com` means the person who signs in with Google under that
address, `user:default/jane_example.com`. `role` is `member` or `owner`; left
out, it is `member`.

A user's name is their GitHub login for GitHub sign-in. Google sign-in exists
only on the Worker, where the name is made from the whole email address:

- the part before the `@`, then `_`, then the domain, in lower case:
  `jane@example.com` is `jane_example.com`;
- a character before the `@` that is not a letter, a digit, a dot or a dash is
  written as `_`, its Unicode code point in hex, `_`: `jane+work@example.com`
  is `jane_2b_work_example.com`.

No two addresses give the same name. A Google name always has a `.` in it,
from the domain, and no GitHub login has one, so a Google account is never
the same user as a GitHub account or as
another Google account. An address whose name would be longer than 63
characters or would not start with a letter or digit, or whose domain has no
dot in it, cannot sign in or be invited. The function is `googleUserName` in
`rules.ts`.

### Errors

A refusal has the matching HTTP status and the body
`{ "error": "<message>" }`. The messages are written to be shown to the user
as they are.

| Status | When                                                                                                                                                            |
| ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | The body is not a JSON object, or a name, slug, colour, theme, role, user reference or logo is not valid                                                        |
| 401    | No valid token on a call that needs one. Answered by the framework in the Backstage error format (`{ "error": { "name", "message" }, ... }`)                    |
| 403    | The caller is not a member, is not an owner, is the guest account creating an organisation, or asks for every organisation without being a portal administrator |
| 404    | No such organisation, logo, member, invitation or call                                                                                                          |
| 409    | The slug or the name is taken; the caller already has an organisation; the user is already a member or invited; the call would remove the last owner            |
| 413    | A JSON body over 16 KB, or a logo over 1 MB                                                                                                                     |

The checks run in this order: signed in, the organisation exists, the
caller's role, then what was sent. A caller who is not allowed is told so
whatever they sent. A portal administrator who is not an owner is refused
like anyone else on every call but `DELETE /:slug`. A slash at the end of an
address makes no difference.

## Other readers of the organisations API

- The document templates (`templates/docs-architecture-c4`,
  `templates/docs-delivery-pack`) ask for an optional **Organisation address**,
  the organisation's full address (`https://portal.example.org/o/acme`), and
  keep it as `portal_url` in the generated repository's `brand.yaml`. When
  it is set, the exports use the
  organisation's name, its primary colour (or its theme's colour) and its full
  logo. `docs-architecture-c4` places PNG, JPEG and SVG logos in its PDF and
  Word documents; `docs-delivery-pack` places PNG and JPEG logos in its PDF and
  Word documents, and the name in its workbook. A logo of another type is left
  out. Left empty, the exports use the values in `brand.yaml`.
- The VM install check (`.github/workflows/vm-install.yml`) expects a new
  portal to answer 404 for `GET /api/organisations/acme` and 401 for
  `GET /api/organisations`.

## Storage

| What   | Worker                                                                          | Node backend (VM, containers)                                                |
| ------ | ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Tables | D1, created by `edge/migrations/0006_organisations.sql` and `0007_accounts.sql` | The `organisations` plugin's database (SQLite or Postgres), made at start-up |
| Logos  | A BLOB column                                                                   | A binary column (SQLite BLOB, Postgres `bytea`)                              |

Both keep the same four tables: `organisations`, `organisation_members`,
`organisation_invitations` and `organisation_logos`. In both,
`organisation_members.user_ref` is the primary key, which limits a user to one
organisation, and the three other tables reference `organisations` by slug so
that deleting one removes its rows.

`organisations` has two columns the API never returns, each unique:

- `id`: 32 lower-case hex digits, random, set when the organisation is
  created and never changed. The organisation's account is
  `organisation:<id>`.
- `name_key`: the name as it is compared (`nameKey` in `rules.ts`).

A change of address is one transaction on both: a second row is made under
the new slug with the same `id`, the members, invitations and logos are moved
to it, and the first row is removed. Neither relies on the database updating
references by itself.

The account a registered catalog file belongs to is kept with the file: in
`locations.account` on the Worker, and in `location_accounts`, a table beside
the catalog's own `locations`, on the Node backend.

## How it is checked

- `packages/backend/src/organisations/cases.json` is one table of cases:
  requests and the answers they must get. The Node backend runs it in its unit
  tests (`packages/backend/src/__tests__/organisations.test.ts`,
  `yarn workspace backend test organisations`), on an in-memory SQLite
  database. With a connection string in `ORGANISATIONS_TEST_POSTGRES` the same
  tests run on that Postgres server instead, each in a schema of its own that
  is dropped afterwards.
- The Worker runs the same table against a local database. Apply the
  migrations (`yarn workspace @internal/edge db:migrate:local`), make sure
  `edge/.dev.vars` has `SESSION_SECRET`, start the Worker with
  `yarn workspace @internal/edge dev`, then run
  `yarn workspace @internal/edge verify:organisations`. The check signs its
  own callers' tokens, creates organisations in the database of the Worker it
  is pointed at and deletes them again, so it refuses any address that is not
  on this machine. Do not run it against a local Worker that is bound to the
  deployed database (`wrangler.pipeline.jsonc`).
- The cases need one portal administrator,
  `user:default/organisations-check-admin`. The Node tests answer for it
  themselves. The Worker check adds a row for it to `branding_admins` in the
  local database (`wrangler d1 execute --local`) and removes it when it is
  done; nobody can sign in as that user. While the row is there the portal has
  an administrator, so the first person to sign in does not become one.
- The Node tests also cover what the cases cannot see: that a deleted
  organisation's account is passed to its longest-standing owner, and that
  tables from before `id` and `name_key` are given both.
- The VM install check asks a freshly installed portal, as above.

Not among the cases: a logo or a JSON body over the size limit, two requests
racing each other, and sign-in itself.

## Upgrading to unique names and accounts

- Organisations whose names already differ only in letter case keep them. The
  oldest holds the name, so nobody else can take it. A later one keeps showing
  the same name without holding it, until an owner renames it.
  On the Worker the migration compares the existing names by case alone, in
  the letters a to z: two existing names that differ in spacing, in an
  accented letter's case or in how a character is written are both held as
  they are, and each is compared in full again once an owner saves it.
- Worker, in this order:
  1. Make sure the person who should receive the files registered so far is
     the first on the list at `/admin/administrators`. The migration looks at
     that list only, not at `PORTAL_ADMINS`, and skips groups. With nobody
     there, those files are shown to nobody until an administrator registers
     each of them again.
  2. Apply migration `0007_accounts.sql`
     (`yarn workspace @internal/edge db:migrate:remote`, which names the
     database as `edge/package.json` and `edge/wrangler.jsonc` do: change both
     to yours). It adds columns and fills them.
  3. Deploy the new Worker straight away. Until then the previous Worker
     still runs on the migrated database, but an organisation it creates
     there has no id and no name key: its name is not held, and nothing can
     be filed under it. The new Worker does not run on a database without
     the migration.
- Node backend: the columns are added at start-up, to SQLite and Postgres
  alike. At the same start the files registered so far are handed to the
  first portal administrator: the person added first to the list, failing
  that the first person named in `PORTAL_ADMINS`. With no administrator they
  are shown to nobody, and are handed over within a minute of the portal
  getting one. See
  [Accounts](accounts.md#files-registered-before-accounts-existed).
- Worker, Google sign-in: a person who signed in with Google before was named
  by the part of their address before the `@`. The first time they sign in
  again, or their session is refreshed, they get their new name, and what
  they had under the old one is carried over in one transaction: settings,
  membership and invitations, template runs, the portal administrator role
  and what they registered. This happens only while the user last recorded
  under the old name is that Google account, and only when the old name is
  not on `GITHUB_ALLOWED_USERS`: a GitHub account that may sign in under the
  name could own what is there. If a GitHub user of that name has signed in
  since, the old name was a GitHub user's all along, or it is on that list,
  nothing is moved, and the Google account starts afresh under its new name.
  If two Google addresses shared the old name, what is under it goes to the
  one that was recorded last.
- Worker, people: a registered catalog file can no longer stand in for a
  person. A `User` entity in a file somebody registered is replaced by the
  person's own entry when they sign in; only a file the operator configured
  defines a user in place of the sign-in.
- `PORTAL_ADMINS` and the sign-in allow-lists are not rewritten. A Google
  user named in `PORTAL_ADMINS` by the short name has to be named by the new
  one (`jane_example.com`).

## Upgrading from portal-wide branding

Before organisations the portal had one name, logo and theme, set by a portal
administrator and shown to everyone, including on the sign-in page. They are
not copied into any organisation. After upgrading, the portal is plain; to get
the look back, create an organisation and set it again.

- Worker: migration `0006_organisations.sql` only adds tables, so
  it can be applied (`yarn workspace @internal/edge db:migrate:remote`) before
  the new Worker is deployed, and the previous Worker can be rolled back to.
  `branding_settings` and `branding_logos` stay in D1, unread.
- Node backend: the old settings and logo tables stay in the
  `branding-settings` plugin's database, unread.

`branding_admins` is still used on both: it is the list of portal
administrators, served at `/api/branding-settings/admins`.

## Known limits

- Sign-in on the Worker is limited to the accounts listed in
  `GITHUB_ALLOWED_USERS`, `GOOGLE_ALLOWED_EMAILS` and `GOOGLE_ALLOWED_DOMAINS`.
- People are shown by their user name, so someone who signs in with Google is
  listed as `jane_example.com`.
- An invitation is to a user name. One sent to a mistyped GitHub login or
  email address waits for whoever signs in under it.
- On a VM or in containers the GitHub sign-in accepts any GitHub account, so
  anyone who can reach the portal can create an organisation with any name
  and logo at any free address.
