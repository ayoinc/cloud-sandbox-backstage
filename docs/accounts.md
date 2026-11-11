# Accounts: what is private and what is shared

Many people and organisations can use one portal. This page says what each of
them can see. The rules are the same however the portal is hosted; where a
host differs, the difference is named.

Words used here:

- **Operator**: whoever deploys and configures the portal.
- **Portal administrator**: a person on the list at `/admin/administrators`,
  or named in the `PORTAL_ADMINS` setting. See
  [Organisations](organisations.md#what-is-separated).
- **Entry**: a catalog entity, such as a component, an API or a template.
- **Registering a file**: adding a catalog file (`catalog-info.yaml`) to the
  catalog by its address, on the Register Existing Component page, or by a
  template run that registers what it created.
- **Serverless host**: the build in `edge/`, a Worker with an SQL database
  beside it. The other host is the Backstage Node backend on a **virtual
  machine or in containers**. [Hosting parity](hosting-parity.md) compares
  them.

## What an account is

An account is whoever a thing in the portal belongs to:

- an **organisation**, for people who are in one;
- **one person**, for someone who is in no organisation.

You see what belongs to you and what belongs to your organisation. You do not
see what belongs to another person or to another organisation. Owning an
organisation, or being a portal administrator, gives you no view into anyone
else's.

Guest sign-in is one account shared by everyone who uses it. Whatever one
guest registers or starts, every guest sees. Sign in with your own account to
keep things to yourself.

## What is private

| Thing                                                                         | Who sees it                                                                                                             |
| ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Entries from a file you registered                                            | Your account: your organisation if you were in one, otherwise you                                                       |
| Entries a template run of yours registered                                    | The same                                                                                                                |
| Search results, documentation and build runs of an entry                      | Whoever sees the entry                                                                                                  |
| Template runs, their form values and their logs                               | The person who started the run. On the serverless host the run happens in the operator's pipeline repository: see below |
| Your settings, starred entries and recent visits                              | You                                                                                                                     |
| An organisation's members and invitations                                     | Its members; an invited person sees their own invitation                                                                |
| Your entry in the list of users, made when you sign in (serverless host only) | You, and the members of your organisation                                                                               |

Something you cannot see answers exactly as something that does not exist,
and is not counted in totals or filters.

There are two exceptions.

- Names and file addresses are portal-wide. Registering a file that another
  account has registered is refused at once. An entry whose kind, namespace
  and name another account's entry has is refused when the catalog reads the
  file: the entry does not appear. Either tells you that something of that
  name exists, though not whose it is or what is in it.
- On a virtual machine or in containers, a shared entry that a private entry
  points at, such as the group that owns it or the system it is part of,
  lists the private entry's name among its relations. The serverless host
  leaves such relations out.

Who may register a file (one file by its address: an address with a
wildcard in it is refused):

- Serverless host: a portal administrator, on the Register Existing Component
  page. Anyone's template run registers what it creates.
- Virtual machine or containers: anyone who is signed in.

## What the portal's own access reaches

The portal reads GitHub with one token of its own, which the operator gives
it. Two things follow, on every host.

- Whoever may register a file can have the portal read any catalog file
  that token can read, and a template runs with it. Give the token access
  only to repositories that the people who may register files and write
  templates are allowed to see.
- The documentation shown for an entry from a registered file is only ever
  that of the repository the file is in: a file cannot name another
  repository to have its pages shown. The same holds for build runs on the
  serverless host, where the portal fetches them; on a virtual machine or in
  containers your browser fetches them from GitHub as you.

On the serverless host templates run, and the catalog is read, in a pipeline
repository's workflow runs. The portal does not put the form values or the
name of the person in the run: the run fetches them from the portal, and its
log names the steps only, and the error when a run fails. Keep that
repository private all the same, and leave `PORTAL_VERBOSE_LOG` unset: with
it set, the log holds what the template's steps print. Through the portal,
you see the steps of your own run; only portal administrators see that
repository's other runs.

## What portal administrators can do

Portal administrators run the portal; they do not read through it. An
administrator sees the same entries as anyone else in their account. They
can:

- manage the list of administrators, list the organisations on the portal
  (name, address, number of members, owners) and remove one, at
  `/admin/administrators`;
- reassign ownership, at `/admin/ownership`, of the entries they can see;
- unregister a file of their own account, and see and unregister a
  registered file that belongs to nobody, though not its entries;
- register a file, on the serverless host, and use the template editor;
- run the templates that change the operator's GitHub organisation: its
  teams, their members and who is invited to it.

The guest account is never a portal administrator.

On a virtual machine or in containers, the members of a group called
`admins`, `platform-admins` or `backstage-admins` in the operator's own
files or GitHub organisation sync can also unregister files, delete
entries, use the template editor and run those templates. A group of that
name in a file somebody registered gives nothing.

If `PORTAL_ADMINS` is empty and the list is empty, the first person to sign
in with their own account becomes the administrator, whoever they are. Set
`PORTAL_ADMINS` before the portal can be reached by people you do not know.

## What is shared

- The catalog files the operator names in the portal's configuration: the
  built-in templates, and whatever else the operator lists there. Everyone
  who is signed in sees them.
- The users and groups the operator's files provide and, on a virtual
  machine or in containers, its GitHub organisation sync. On the serverless
  host a person the operator's files list is shown to everyone only until
  that person signs in; from then on their entry is their own.
- An organisation's name, address, logo and colours. They are shown on its
  sign-in page, before anyone has signed in.

## Moving between accounts

- A file is filed when it is registered. If you register a file on your own
  and join an organisation later, the file stays yours alone. To give it to
  the organisation, unregister it and register it again. You can unregister
  only a file of your own account, and only as a portal administrator; on
  the serverless host the file can then be registered for another account
  only some hours later, once nothing of it is left in the catalog.
- A file that is unregistered is shown to nobody from that moment, and its
  entries leave the catalog when the catalog next reads its files.
- If you leave an organisation, what was registered for the organisation
  stays with it.
- When an organisation is deleted, by an owner or by a portal administrator,
  the files registered for it pass to the owner who has been one longest, as
  that person's own. The other former members no longer see them. On a
  virtual machine or in containers the new owner sees them once the catalog
  has read the files again, which it is asked to do at once.
- Changing an organisation's name or address changes nothing about what
  belongs to it.

## One person, one account

GitHub sign-in names you by your GitHub login: `user:default/jane`.

Google sign-in, which the serverless host offers, names you by your whole
email address: `jane@example.com` is `user:default/jane_example.com`. A
Google name always has a `.` in it and a GitHub login never does, so the two
can never be the same
name. To invite someone who signs in with Google, give their email address.

A serverless portal that ran before this rule named Google users by the part
of the address before the `@`. The next time such a person signs in, their
settings, organisation, template runs and registered files move to the new
name, as long as the old name was last used by that same Google account and
is not on `GITHUB_ALLOWED_USERS`. If a
GitHub user of that name has signed in since, nothing moves and the Google
account starts afresh. If two Google addresses shared the old name, what is
under it goes to the one that signed in last before the upgrade. If
`PORTAL_ADMINS` names such a person, change it to the new name.
[Organisations](organisations.md) has the details.

## Files registered before accounts existed

They were visible to everyone signed in. At the upgrade they are handed to
one administrator, or to that person's organisation if they are in one.
Check who that is before you upgrade.

| Host                          | Who receives them                                                                                                | If there is nobody                                                                                                                                         |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Serverless                    | The person added first to the list at `/admin/administrators`. `PORTAL_ADMINS` and groups are not looked at      | The files are shown to nobody. An administrator finds them in the list of registered files (`GET /api/catalog/locations`) and registers each of them again |
| Virtual machine or containers | The person added first to that list; failing that, the first person named in `PORTAL_ADMINS`. Groups are skipped | The files are shown to nobody. They are handed over within a minute of the portal getting an administrator                                                 |

On a virtual machine or in containers the catalog has to read each of those
files once after the upgrade before its entries are private. Until then,
which takes a few minutes, they are still shown to everyone signed in, as
they were before.

## How each host does it

| Host                          | How an entry gets its account                                                                                                                                                                                                                                       | How reads are limited                                                                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Virtual machine or containers | The catalog writes the account on each entry as an annotation (`portal/account`) while it reads the file. A file cannot set it. A newly registered file's entries are hidden from everyone until the catalog has read it once more, which it is asked to do at once | The permission policy allows an entry only when the annotation is absent or names one of your accounts. `permission.enabled` must stay `true` |
| Serverless                    | The registered file keeps its account, and an entry is matched to its file each time it is read. Entries appear after the next catalog sync                                                                                                                         | Every query that reads an entry, or anything made from one, carries the same test                                                             |
