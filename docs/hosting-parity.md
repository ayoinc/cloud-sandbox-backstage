# Hosting parity

The portal runs three ways. This page records what each one does today, so a
difference is a known gap with an owner rather than a surprise.

| Host               | What runs                                                                                                     | Where the heavy work happens                                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Virtual machine    | The Node backend as a systemd service, with PostgreSQL beside it (`scripts/install-vm.sh`)                    | In the backend process                                             |
| Containers         | The same backend as an image, behind nginx, with PostgreSQL, Redis and object storage (`docker-compose.yaml`) | In the backend process                                             |
| Cloudflare Workers | A Worker serving the app and answering the Backstage APIs from D1 and R2 (`edge/`)                            | In GitHub Actions, on a real Backstage backend started for the run |

## What works where

| Capability                                           | VM and containers          | Workers                                                                                                   |
| ---------------------------------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------- |
| Catalog browsing, entity pages, relations graph      | Yes                        | Yes                                                                                                       |
| Search                                               | Yes (PostgreSQL)           | Yes (SQLite full-text; results can rank differently)                                                      |
| Documentation pages                                  | Yes, built on request      | Yes, built by `portal-sync`                                                                               |
| D2 diagrams in documentation                         | Yes                        | Yes                                                                                                       |
| Creating from a template                             | Yes, in process            | Yes, in `portal-scaffold`                                                                                 |
| Live progress of a template run                      | Task log                   | Task log plus the run's GitHub Actions steps                                                              |
| Template editor and trying a template out            | Yes                        | Yes, administrators only, in `portal-dry-run` (about 80 seconds)                                          |
| Registering an existing component                    | Yes                        | Yes, administrators only, GitHub links to a catalog file                                                  |
| Refreshing an entity, removing a registered location | Yes                        | Administrators only; takes effect at the next sync                                                        |
| Deleting a single entity                             | Yes                        | No                                                                                                        |
| Branding: name, logo, theme preset, colour           | Yes, logos in the database | Yes, logos in D1                                                                                          |
| API explorer                                         | Yes                        | Yes. "Try it out" calls the API from the browser on every host, so the API must allow the portal's origin |
| Ownership management                                 | Yes                        | Yes                                                                                                       |
| Sign-in with GitHub                                  | Yes                        | Yes                                                                                                       |
| Sign-in with Google                                  | No                         | Yes                                                                                                       |
| Notifications                                        | Yes                        | Empty inbox; nothing produces them                                                                        |
| Cancelling or retrying a template run                | Yes                        | No                                                                                                        |
| Kubernetes, proxy-backed plugins                     | When configured            | No                                                                                                        |

## Known differences

| Difference                                               | Effect                                                                                   | Plan                                                                     |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| The first administrator                                  | Workers: the first person to sign in, or `PORTAL_ADMINS`. Node: `BRANDING_INITIAL_ADMIN` | Honour `PORTAL_ADMINS` and the first-sign-in rule on Node                |
| Google sign-in is Workers only                           | A VM or container deployment cannot offer it                                             | Add the provider to the Node backend                                     |
| Template runs need GitHub Actions on Workers             | A Workers deployment cannot run templates from a self-hosted runner                      | Make the dispatch pluggable, so a container can run the pipeline scripts |
| Cancel and retry of a run on Workers                     | The buttons are hidden                                                                   | Cancel through the Actions API                                           |
| Ownership: a `user:` owner is never an orphan on Workers | Orphan counts can differ                                                                 | Check users against the catalog on both                                  |

## How it is checked

`edge/scripts/compare-with-backend.mjs` compares the Worker's catalog answers
with a Node backend's. Every template is rendered by the real scaffolder on
each push (`template-check.yml`), whichever host it will be used from. The
VM installer is run on a fresh Ubuntu machine, and the service asked for its
health, whenever it or the backend changes (`vm-install.yml`).
