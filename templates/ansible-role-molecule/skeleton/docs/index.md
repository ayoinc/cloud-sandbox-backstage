# ${{ values.name }}

${{ values.description }}

## What the role does

1. Checks that the target is a supported distribution family.
2. Installs the base packages for that family plus `${{ values.rolePrefix }}_packages`.
3. Renders `${{ values.rolePrefix }}_settings` as an INI file at `${{ values.rolePrefix }}_config_file`.
4. If `${{ values.rolePrefix }}_service_name` is set, enables the unit and restarts it whenever the file changes.

## Layout

```
${{ values.name }}/
├── defaults/main.yml           # Public variables and their defaults
├── vars/                       # Per-distribution internals
├── tasks/                      # main.yml imports install, configure, service
├── handlers/main.yml           # Restart on configuration change
├── templates/config.ini.j2     # The rendered file
├── meta/main.yml               # Galaxy metadata
├── meta/argument_specs.yml     # Typed role arguments
└── molecule/default/           # Test scenario
```

## Summary

| Setting | Value |
| --- | --- |
| Role name | `${{ values.rolePrefix }}` |
| Variable prefix | `${{ values.rolePrefix }}_` |
| Owner | `${{ values.owner }}` |
| Molecule driver | `${{ values.moleculeDriver }}` |
| Tested on | ${{ values.distros | join(', ') }} |
