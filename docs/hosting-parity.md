# Hosting parity

The portal runs three ways. This page records what each one does today, so a
difference is a known gap with an owner rather than a surprise.

| Host               | What runs                                                                                                     | Where the heavy work happens                                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Virtual machine    | The Node backend as a systemd service, with PostgreSQL beside it (`scripts/install-vm.sh`)                    | In the backend process                                             |
| Containers         | The same backend as an image, behind nginx, with PostgreSQL, Redis and object storage (`docker-compose.yaml`) | In the backend process                                             |
| Cloudflare Workers | A Worker serving the app and answering the Backstage APIs from D1 and R2 (`edge/`)                            | In GitHub Actions, on a real Backstage backend started for the run |

## What works where

| Capability                                                                                          | VM and containers                                           | Workers                                                                                                   |
| --------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Catalog browsing, entity pages, relations graph                                                     | Yes                                                         | Yes                                                                                                       |
| Search                                                                                              | Yes (PostgreSQL)                                            | Yes (SQLite full-text; results can rank differently)                                                      |
| Documentation pages                                                                                 | Yes, built on request                                       | Yes, built by `portal-sync`                                                                               |
| D2 diagrams in documentation                                                                        | Yes                                                         | Yes                                                                                                       |
| Creating from a template                                                                            | Yes, in process                                             | Yes, in `portal-scaffold`                                                                                 |
| Live progress of a template run                                                                     | Task log                                                    | Task log plus the run's GitHub Actions steps                                                              |
| Template editor and trying a template out                                                           | Yes, administrators only                                    | Yes, administrators only, in `portal-dry-run` (about 80 seconds)                                          |
| Registering an existing component                                                                   | Yes                                                         | Yes, administrators only, GitHub links to a catalog file                                                  |
| Refreshing an entity, removing a registered location                                                | Refresh: yes. Removing: administrators only; hidden at once | Administrators only; a removed file is hidden at once and gone at the next sync                           |
| Deleting a single entity                                                                            | Administrators only                                         | No                                                                                                        |
| [Organisations](organisations.md): address, look, members                                           | Yes, logos in the database                                  | Yes, logos in D1                                                                                          |
| [Private by default](accounts.md): each account sees its own entries, search results, docs and runs | Yes, by the permission policy                               | Yes, in every query                                                                                       |
| API explorer                                                                                        | Yes                                                         | Yes. "Try it out" calls the API from the browser on every host, so the API must allow the portal's origin |
| Ownership management                                                                                | Yes, administrators only                                    | Yes, administrators only                                                                                  |
| Sign-in with GitHub                                                                                 | Yes                                                         | Yes                                                                                                       |
| Sign-in with Google                                                                                 | No                                                          | Yes                                                                                                       |
| Counting visits (Cloudflare Web Analytics, no cookies)                                              | No                                                          | When `WEB_ANALYTICS_TOKEN` is set                                                                         |
| Privacy, cookies, guides and sitemap pages                                                          | Yes                                                         | Yes                                                                                                       |
| Notifications                                                                                       | Yes                                                         | Empty inbox; nothing produces them                                                                        |
| Cancelling or retrying a template run                                                               | Yes                                                         | No                                                                                                        |
| Kubernetes, proxy-backed plugins                                                                    | When configured                                             | No                                                                                                        |

## Known differences

| Difference                                                                                                     | Effect                                                                                                                                   | Plan                                                                     |
| -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Google sign-in is Workers only                                                                                 | A VM or container deployment cannot offer it                                                                                             | Add the provider to the Node backend                                     |
| Template runs need GitHub Actions on Workers                                                                   | A Workers deployment cannot run templates from a self-hosted runner                                                                      | Make the dispatch pluggable, so a container can run the pipeline scripts |
| Cancel and retry of a run on Workers                                                                           | The buttons are hidden                                                                                                                   | Cancel through the Actions API                                           |
| Ownership: a `user:` owner is never an orphan on Workers                                                       | Orphan counts can differ                                                                                                                 | Check users against the catalog on both                                  |
| People who sign in are catalog users on Workers only                                                           | On a VM or container the list of users is what the operator's files and GitHub organisation sync provide, shared with everyone signed in | Record sign-ins as users on the Node backend, private in the same way    |
| A newly registered file's entries are hidden for a moment on a VM or container                                 | Until the catalog has read the file once more, which it is asked to do at once                                                           | None needed: hidden is the safe side                                     |
| After upgrading a VM or container, files registered earlier stay shown to everyone signed in for a few minutes | Until the catalog has read each of them once ([Accounts](accounts.md#files-registered-before-accounts-existed))                          | None: they were shown to everyone before the upgrade                     |

## How it is checked

`edge/scripts/compare-with-backend.mjs` compares the Worker's catalog answers
with a Node backend's. Every template is rendered by the real scaffolder on
each push (`template-check.yml`), whichever host it will be used from. The
VM installer is run on a fresh Ubuntu machine, and the service asked for its
health, whenever it or the backend changes (`vm-install.yml`).

That one account sees nothing of another's is checked on each backend. On
the Worker, `edge/scripts/check-privacy.mjs` signs in as five people (two on
their own, members of two organisations, an administrator) against a local
Worker and asks every route that reads an entry what each of them gets. On
the Node backend, the unit tests cover the permission policy's answers
(`permissionPolicy.test.ts`) and the stamping and recording of accounts
(`accounts.test.ts`); the stock catalog, search and documentation plugins
apply those answers.
