# ${{ values.name }}

${{ values.description }}

Policies for Terraform and OpenTofu, kept in one place and applied to every repository through a reusable workflow.

| Layer | Tool | Looks at | Lives in |
| --- | --- | --- | --- |
| Plan policies | [OPA](https://www.openpolicyagent.org) and [Conftest](https://www.conftest.dev) | The plan as JSON: what would really change | `policy/terraform/` |
| Static checks | [Checkov](https://www.checkov.io) | The configuration: built-in checks and the custom ones here | `checkov/` |
| Lint | [TFLint](https://github.com/terraform-linters/tflint) | The configuration: conventions and mistakes | `tflint/` |

## Plan Policies

| Package | Denies |
| --- | --- |
| `terraform.tagging` | Taggable resources without the required tags or labels |
| `terraform.deletion` | Deleting or replacing a protected resource type; warns about every other deletion |
| `terraform.network` | SSH or RDP reachable from the whole internet (AWS, Azure, Google Cloud) |
| `terraform.storage` | Public buckets, containers and storage accounts; storage accounts on old TLS |
| `terraform.providers` | Providers from an unapproved namespace or without a version constraint |

The settings they share are in `policy/terraform/config.rego`: the required tags, the protected types, the exemptions, the provider namespaces and the administrative ports. Change the policy of your organisation there, in a reviewed commit.

Each policy has a `_test.rego` file next to it. `tests/fixtures/plans/` holds a compliant and a violating plan, and `violating.expected.txt` lists exactly what the policies must report for the latter.

## Using the Policies

Call the reusable workflow from the pipeline of a Terraform repository. Pin `@v1` and `policy-ref` to the same tag.

```yaml
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      # ... checkout, sign in, terraform init ...
      - run: terraform plan -out=tfplan
      - run: terraform show -json tfplan > tfplan.json
      - uses: actions/upload-artifact@v7
        with:
          name: tfplan-json
          path: tfplan.json
          retention-days: 1

  policy:
    needs: plan
    uses: ${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/terraform-policy.yaml@v1
    with:
      policy-ref: v1
      plan-artifact: tfplan-json
```

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory of the configuration |
| `policy-ref` | `main` | Tag, branch or commit of the policies |
| `plan-artifact` | empty | Artifact with plans as JSON; without it only the static checks run |
| `tflint` | `true` | Run TFLint with the shared configuration |
| `checkov` | `true` | Run Checkov with the shared configuration and the custom checks |

A plan as JSON contains every value of the configuration, secrets included. Keep the retention of the artifact short, as above.

This repository is private. Allow other repositories to use it under Settings → Actions → General → Access, or pass a token that can read it as the `policy-token` secret.

To run the plan policies on a workstation:

```bash
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy policy --all-namespaces
```

## Exceptions

| For | How |
| --- | --- |
| Deleting one protected resource | Add its address to `deletion_exemptions` in `config.rego`, release, and remove it afterwards |
| One resource and one Checkov check | A `#checkov:skip=<ID>:<reason>` comment on the resource, in its own repository |
| A Checkov check for everyone | Add the ID to `skip-check` in `checkov/config.yaml`, with the reason |
| One TFLint finding | A `# tflint-ignore: <rule>` comment above the line |

## Developing

Install OPA, Conftest, jq, TFLint and Checkov, then:

```bash
make fmt        # format the policies
make all        # everything the pipeline runs
```

| Target | Checks |
| --- | --- |
| `make fmt-check` | The policies are formatted |
| `make check` | The policies compile in strict mode |
| `make test` | Unit tests (`conftest verify`) |
| `make plans` | The fixture plans produce exactly the expected results |
| `make checkov` | The custom checks pass the compliant fixture and fail the violating one |
| `make tflint` | The shared configuration passes the compliant fixture and fails the violating one |

To add a plan policy, create `policy/terraform/<name>.rego` in the package `terraform.<name>` with `deny contains msg if` rules (or `warn`), add `<name>_test.rego`, extend `tests/fixtures/plans/violating.json` and add the new message to `violating.expected.txt`.

To add a Checkov check, add a YAML file to `checkov/policies/` with the next free `CKV2_CUSTOM_<n>` ID, list the ID in `CHECKOV_CHECKS` in the `Makefile` and cover it in both fixtures under `tests/fixtures/terraform/`.

## Releasing

Callers pin a tag. Create `v1.0.0` for a release and move the major tag along: `git tag -f v1 && git push -f origin v1`. Tighten a policy as a warning first (`warn`) and turn it into a `deny` in the next major version, so that callers can fix their findings before they are blocked.

## Owner

These policies are owned by **${{ values.owner }}**.
