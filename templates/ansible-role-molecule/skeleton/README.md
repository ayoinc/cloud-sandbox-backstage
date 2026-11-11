# ${{ values.name }}

${{ values.description }}

An Ansible role that installs packages, renders `/etc/${{ values.rolePrefix }}/${{ values.rolePrefix }}.conf` and
optionally keeps a systemd unit in step with that file. It is the starting
point for the role's real behaviour: replace the tasks, keep the structure.

## Requirements

- ansible-core 2.18 or newer on the controller
- A Debian-family or Enterprise Linux target with Python 3.9 or newer
- Privilege escalation on the target (`become: true`)

## Usage

```yaml
- name: Apply the role
  hosts: all
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        ${{ values.rolePrefix }}_packages:
          - jq
        ${{ values.rolePrefix }}_settings:
          general:
            log_level: warning
```

Role arguments are typed in `meta/argument_specs.yml`; Ansible rejects a wrong
type or an unknown choice before the first task runs. `docs/variables.md`
lists them.

## Development

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml

yamllint .
ansible-lint
molecule test                           # ${{ values.distros[0] }}
MOLECULE_DISTRO=${{ values.distros | last }} molecule test
```

Molecule uses the ${{ values.moleculeDriver }} driver. `molecule converge` followed
by `molecule login` leaves an instance running to inspect.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand: yamllint
and ansible-lint (`production` profile), then Molecule once per distribution:
{%- for distro in values.distros %}
- `${{ distro }}`
{%- endfor %}

## License

MIT

## Author

${{ values.owner }}
