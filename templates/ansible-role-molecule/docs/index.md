# Ansible Role with Molecule

Creates a standalone Ansible role repository that is tested from its first
commit: Molecule converges the role in systemd-enabled containers on every
distribution you select, checks that a second run changes nothing, and runs a
verify playbook against the result.

## What you get

| Path                                                      | Purpose                                                                                                   |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `defaults/`, `vars/`, `tasks/`, `handlers/`, `templates/` | A working role that installs packages, renders a configuration file and optionally manages a systemd unit |
| `meta/main.yml`                                           | Galaxy metadata                                                                                           |
| `meta/argument_specs.yml`                                 | Typed role arguments, validated before any task runs                                                      |
| `molecule/default/`                                       | Create, converge, idempotence and verify scenario                                                         |
| `.ansible-lint`                                           | `production` profile, the strictest one                                                                   |
| `.github/workflows/ci.yaml`                               | yamllint, ansible-lint and a Molecule matrix over the selected distributions                              |
| `docs/`, `mkdocs.yml`                                     | TechDocs for the portal                                                                                   |

## Parameters

| Parameter       | Description                                                                                             |
| --------------- | ------------------------------------------------------------------------------------------------------- |
| Name            | Repository and component name. Hyphens become underscores in the role name and in the variable prefix   |
| Molecule driver | `docker` or `podman`; decides the driver plugin, the platform definition and the pinned test collection |
| Distributions   | Container images the role is tested on; each becomes a matrix job                                       |

## After scaffolding

1. Replace the example behaviour in `tasks/` with what the role should do, keeping every variable prefixed with the role name.
2. Describe each new variable in `meta/argument_specs.yml`; ansible-lint and Ansible itself check the role against it.
3. Extend `molecule/default/verify.yml` with assertions for the new behaviour.

Versions of ansible-core, ansible-lint and Molecule are pinned in `requirements-dev.txt`.
