# Variables

All public variables carry the `${{ values.rolePrefix }}_` prefix and are declared in
`meta/argument_specs.yml`, which is the authoritative reference.

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `${{ values.rolePrefix }}_packages` | list of str | `[]` | Extra packages to install |
| `${{ values.rolePrefix }}_update_cache` | bool | `true` | Refresh the package cache first |
| `${{ values.rolePrefix }}_config_dir` | path | `/etc/${{ values.rolePrefix }}` | Configuration directory |
| `${{ values.rolePrefix }}_config_file` | path | `<config_dir>/${{ values.rolePrefix }}.conf` | Rendered file |
| `${{ values.rolePrefix }}_config_owner` | str | `root` | Owner of directory and file |
| `${{ values.rolePrefix }}_config_group` | str | `root` | Group of directory and file |
| `${{ values.rolePrefix }}_config_mode` | str | `'0640'` | Mode of the file |
| `${{ values.rolePrefix }}_settings` | dict | one `general` section | Section to option to value |
| `${{ values.rolePrefix }}_service_name` | str | `''` | Unit to manage; empty for none |
| `${{ values.rolePrefix }}_service_state` | str | `started` | `started` or `stopped` |
| `${{ values.rolePrefix }}_service_enabled` | bool | `true` | Start at boot |

## Adding a variable

1. Give it a default in `defaults/main.yml`.
2. Describe it in `meta/argument_specs.yml` with a type and, where it applies, `choices`.
3. Add a row to the table above.
