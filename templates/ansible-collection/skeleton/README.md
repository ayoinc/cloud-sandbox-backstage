# ${{ values.namespace }}.${{ values.collectionName }}

${{ values.description }}

## Content

| Type | Name | Description |
| --- | --- | --- |
| Module | `${{ values.namespace }}.${{ values.collectionName }}.properties_entry` | Manage a single entry in a properties file |
| Filter | `${{ values.namespace }}.${{ values.collectionName }}.to_properties` | Render a dictionary as properties file text |
| Role | `${{ values.namespace }}.${{ values.collectionName }}.properties_file` | Keep entries of a properties file in the declared state |

## Requirements

- ansible-core 2.18 or newer
- Python 3.9 or newer on managed hosts

## Installation

```bash
ansible-galaxy collection install ${{ values.namespace }}.${{ values.collectionName }}
```

Or pin it in a `requirements.yml`:

```yaml
collections:
  - name: ${{ values.namespace }}.${{ values.collectionName }}
    version: 1.0.0
```

Straight from this repository, before a release is published:

```bash
ansible-galaxy collection install git+https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git,main
```

## Usage

```yaml
- name: Configure the application
  hosts: app
  become: true
  tasks:
    - name: Set the listen port
      ${{ values.namespace }}.${{ values.collectionName }}.properties_entry:
        path: /etc/app/app.properties
        key: server.port
        value: "8443"
        mode: "0640"
```

`ansible-doc ${{ values.namespace }}.${{ values.collectionName }}.properties_entry` shows every option.

## Development

`ansible-test` only works when the repository is checked out at
`ansible_collections/${{ values.namespace }}/${{ values.collectionName }}`:

```bash
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git ansible_collections/${{ values.namespace }}/${{ values.collectionName }}
cd ansible_collections/${{ values.namespace }}/${{ values.collectionName }}
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt

ansible-test sanity --docker default
ansible-test units --docker default
ansible-test integration --docker ubuntu2404
ansible-lint
```

Every change needs a fragment in `changelogs/fragments/`; see
`docs/releasing.md`.

## License

MIT. See `LICENSE`.

## Owner

${{ values.owner }}
