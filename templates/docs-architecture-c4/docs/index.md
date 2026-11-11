# Architecture Design (C4 HLD and LLD)

Creates a repository holding the design of one system:

- a **high-level design** (HLD): context, containers, deployment, quality
  attributes, decisions and risks;
- a **low-level design** (LLD), optional: components, a request sequence, the
  data model, interfaces and operational detail.

The diagrams follow the [C4 model](https://c4model.com) and are written in
[D2](https://d2lang.com), one file per diagram in `docs/diagrams/`. They share
one set of shapes and colours (`docs/diagrams/c4.d2`), so every diagram reads
the same way.

## What you get

| Where                      | What                                                   |
| -------------------------- | ------------------------------------------------------ |
| The portal's documentation | The design as pages, diagrams rendered                 |
| `uv run scripts/export.py` | `HLD.pdf`, `HLD.docx`, `LLD.pdf`, `LLD.docx` in `out/` |
| GitHub Actions             | The same files as a build artifact on every push       |

## The look of the exports

The cover, headings and diagram accents take the organisation's name, logo
and primary colour from `brand.yaml`. Fill in **Organisation address** with
your organisation's address in the portal (`https://portal.example.org/o/acme`)
and they are read from the organisation instead, so a change its owner makes
reaches the next export.

## Form fields

| Field                        | Meaning                                      |
| ---------------------------- | -------------------------------------------- |
| Repository Name              | Name of the new repository                   |
| System Name                  | The system being designed                    |
| Include the low-level design | Leave off while only the HLD is being agreed |
| Classification               | Printed on every exported page               |
| Organisation address         | Optional. Your organisation's portal address |
