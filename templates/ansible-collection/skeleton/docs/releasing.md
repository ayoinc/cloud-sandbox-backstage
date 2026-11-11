# Releasing

## Changelog fragments

Each change adds a small YAML file to `changelogs/fragments/`:

```yaml
# changelogs/fragments/42-properties-entry-backup.yml
bugfixes:
  - properties_entry - keep the file mode when a backup is taken (https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/issues/42).
```

Sections: `major_changes`, `minor_changes`, `breaking_changes`,
`deprecated_features`, `removed_features`, `security_fixes`, `bugfixes`,
`known_issues`, and `trivial` for changes users do not need to read about.
New modules and plugins are picked up from their `version_added`.
`antsibull-changelog lint` runs in CI.

## Cutting a release

Versions follow semantic versioning: bug fixes raise the patch number, new
features the minor, breaking changes the major.

```bash
# 1. Set the version in galaxy.yml, then fold the fragments into the changelog
antsibull-changelog release

# 2. Commit CHANGELOG.rst, changelogs/changelog.yaml and galaxy.yml
git commit -am "Release 1.0.0"

# 3. Tag with the bare version and push
git tag 1.0.0
git push origin main 1.0.0
```

The publish workflow refuses a tag that does not match `galaxy.yml` or has no
entry in the changelog. It then builds the artifact, attests its provenance,
creates a GitHub release and uploads to Galaxy.

## Credentials

| Name | Kind | Purpose |
| --- | --- | --- |
| `ANSIBLE_GALAXY_TOKEN` | Repository secret | API token of an account that may upload to the `${{ values.namespace }}` namespace |
| `ANSIBLE_GALAXY_SERVER` | Repository variable, optional | API URL of a private Automation Hub; defaults to Ansible Galaxy |

Without the secret, the upload step is skipped and the release artifact is
still attached to the GitHub release.

## Verifying a download

```bash
gh attestation verify ${{ values.namespace }}-${{ values.collectionName }}-1.0.0.tar.gz --repo ${{ values.destination.owner }}/${{ values.destination.repo }}
```
