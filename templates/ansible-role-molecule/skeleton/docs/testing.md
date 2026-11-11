# Testing

## Scenario

`molecule/default` runs this sequence:

| Stage | What it proves |
| --- | --- |
| syntax | The playbooks parse |
| create, prepare | A systemd container of the chosen distribution starts |
| converge | The role applies cleanly from nothing |
| idempotence | A second run reports no change |
| verify | Packages, file ownership, mode and content are as declared |

## Running

```bash
molecule test                                  # full sequence
molecule converge && molecule verify           # iterate; instance stays up
molecule login                                 # shell in the instance
molecule destroy
```

`MOLECULE_DISTRO` selects the image; the workflow sets it from its matrix.

## Linting

`ansible-lint` runs with the `production` profile: fully qualified module names,
named tasks, explicit file modes, role-prefixed variables and valid Galaxy
metadata are all enforced.
