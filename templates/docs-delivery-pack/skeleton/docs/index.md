# ${{ values.projectName }} delivery

${{ values.description }}

| Page | What it shows |
| --- | --- |
| [Status](status.md) | This period's report: where the project stands and what it needs |
| [Plan](plan.md) | Phases and milestones, with owners, dates and dependencies |
| [RAID log](raid.md) | Risks, assumptions, issues and dependencies |
| [RACI](raci.md) | Who is responsible, accountable, consulted and informed |

The pages are written from the data in `delivery/`. To change one, change
the data and push: the build checks it, rewrites the pages, and keeps an
Excel workbook, a Word document and a PDF as the `delivery-pack` artifact.

| | |
| --- | --- |
| Owner | ${{ values.owner }} |
| Classification | ${{ values.classification }} |
