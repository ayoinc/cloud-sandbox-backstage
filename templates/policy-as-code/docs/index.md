# Policy as Code for Terraform Template

This template creates a repository of policies for Terraform and OpenTofu and a reusable workflow that other repositories call to be checked against them.

## What It Creates

- OPA policies for plans, in Rego v1, run with Conftest: required tags, protected resources, administrative ports open to the internet, public storage and provider sources, for AWS, Azure and Google Cloud resources
- A unit test file for every policy and fixture plans with their expected results
- Custom Checkov checks in YAML and a shared Checkov configuration
- A shared TFLint configuration
- A reusable workflow, `terraform-policy.yaml`, that applies all three to a calling repository
- A pipeline that tests the policies themselves

## Form Fields

| Field               | Description                              |
| ------------------- | ---------------------------------------- |
| Repository Name     | Name of the policy repository            |
| Description         | Whose infrastructure the policies govern |
| Owner               | Team that owns the policies              |
| Repository Location | GitHub repository to create              |

## The Generated Repository

| Path                                      | Content                                                        |
| ----------------------------------------- | -------------------------------------------------------------- |
| `policy/terraform/`                       | Plan policies, their tests and `config.rego` with the settings |
| `checkov/`                                | Checkov configuration and custom checks                        |
| `tflint/`                                 | Shared TFLint configuration                                    |
| `tests/fixtures/`                         | Compliant and violating plans and configurations               |
| `.github/workflows/ci.yaml`               | Pipeline of the repository; runs on push                       |
| `.github/workflows/terraform-policy.yaml` | Reusable workflow; runs only when another workflow calls it    |
| `Makefile`                                | The checks of the pipeline, for local use                      |

### Pipeline

The pipeline needs no cloud account. It checks that the policies are formatted and compile in strict mode, runs their unit tests, and verifies that the fixtures produce exactly the expected results with Conftest, Checkov and TFLint.

### Calling the Policies

The repository is created private. Allow the repositories of your organisation to use its workflow under Settings → Actions → General → Access, then call the reusable workflow as shown in its README.

## Support

Contact the Platform Team for assistance.
