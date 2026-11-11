# Project Delivery Pack

Creates a repository that holds a project's delivery documents as data:

| File                   | What it is                                                 |
| ---------------------- | ---------------------------------------------------------- |
| `delivery/plan.yaml`   | Phases and milestones, with owners, dates and dependencies |
| `delivery/raid.yaml`   | Risks, assumptions, issues and dependencies                |
| `delivery/raci.yaml`   | Who is responsible, accountable, consulted and informed    |
| `delivery/status.yaml` | The current status report                                  |

One command checks the data and builds everything from it:

| Output                              | For                                                                                     |
| ----------------------------------- | --------------------------------------------------------------------------------------- |
| The pages under `docs/`             | Reading in the portal                                                                   |
| `out/delivery-workbook.xlsx`        | People who work in Excel: plan with a timeline, RAID log with scored risks, RACI matrix |
| `out/status-report.docx` and `.pdf` | Sending to a steering group                                                             |

The exports carry the organisation's name, logo and primary colour from
`brand.yaml`, or from the portal's branding settings when the template is
given the portal's address.

Because the documents are data, a change is a reviewed commit, the history
shows who moved a date and why, and nothing has to be kept in step by hand:
the build fails when a milestone depends on one that does not exist, a risk
has no owner, or an activity has no single accountable role.
