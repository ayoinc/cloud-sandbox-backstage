# ${{ values.projectName }} delivery

${{ values.description }}

The delivery documents of ${{ values.projectName }}, kept as data in
`delivery/` and built into pages, an Excel workbook, a Word document and a
PDF.

| Edit | To change |
| --- | --- |
| `delivery/plan.yaml` | Phases, milestones, owners, dates, dependencies |
| `delivery/raid.yaml` | Risks, assumptions, issues, dependencies |
| `delivery/raci.yaml` | Roles and who does what |
| `delivery/status.yaml` | This period's status report |

## Build

```bash
uv run scripts/build.py
```

checks the data, rewrites the pages in `docs/` and writes to `out/`:

- `delivery-workbook.xlsx`: summary, plan with a week-by-week timeline, RAID
  log with scored risks, RACI matrix;
- `status-report.docx` and `status-report.pdf`.

The PDF needs [typst](https://typst.app) on the `PATH`; without it the build
says so and writes everything else.

Every push to `main` runs the same build in GitHub Actions, commits the
rewritten pages so the portal publishes them, and keeps the workbook and the
report as the `delivery-pack` artifact.

## What the build refuses

- A milestone that ends before it starts, or depends on one that does not exist.
- An id used twice.
- A risk without an owner, or scored outside 1 to 5.
- An activity without exactly one accountable role, or naming an unknown role.
- A status that is not one of the allowed words.

## Brand it

`brand.yaml` holds the organisation name, logo and primary colour. Set
`portal_url` there and they are read from the portal's branding settings.
