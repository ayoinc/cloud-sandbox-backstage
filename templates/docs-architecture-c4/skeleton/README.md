# ${{ values.systemName }} design

${{ values.description }}

The design of ${{ values.systemName }}, written as documentation and drawn
with [C4](https://c4model.com) diagrams in [D2](https://d2lang.com).

| Document | Source |
| --- | --- |
| High-level design | `docs/hld.md` |
{%- if values.includeLld %}
| Low-level design | `docs/lld.md` |
{%- endif %}
| Diagrams | `docs/diagrams/*.d2`, sharing the shapes in `docs/diagrams/c4.d2` |

## Read it

The portal publishes these pages as documentation. To preview a change:

```bash
uvx --with mkdocs-techdocs-core==1.7.1 --with mkdocs-d2-plugin==1.7.0 mkdocs serve
```

## Export it

```bash
uv run scripts/export.py
```

writes a PDF and a Word file per document to `out/`, with a cover page,
contents, and the classification on every page. It needs
[pandoc](https://pandoc.org), [typst](https://typst.app),
[d2](https://d2lang.com) and `rsvg-convert` (librsvg) on the `PATH`. Every
push to `main` builds the same files in GitHub Actions and keeps them as the
`design-documents` artifact.

## Brand it

`brand.yaml` holds the organisation name, logo and primary colour used by the
exports. Set `portal_url` there and they are read from the portal's branding
settings, so the documents follow the portal.

```bash
uv run scripts/export.py --sync-brand
```

also writes the primary colour into `docs/diagrams/c4.d2`, which is what the
published pages use. Commit the change.

## Change a diagram

Each diagram is one `.d2` file. Start it with `...@c4` and give every shape a
class from `c4.d2` (`person`, `system`, `external`, `container`, `store`,
`queue`, `boundary`), and it will match the others.
