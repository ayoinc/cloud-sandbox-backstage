# ${{ values.name }}

${{ values.description }}

This repository holds the policies that Terraform and OpenTofu repositories are checked against, and the reusable workflow that applies them.

## What Is Checked

| Layer | Tool | Rules |
| --- | --- | --- |
| Plan policies | OPA and Conftest | Required tags, protected resources, administrative ports, public storage, provider sources |
| Static checks | Checkov | The built-in checks plus an owner tag and an S3 lifecycle configuration |
| Lint | TFLint | Naming, documented and typed variables, version constraints, pinned modules |

## How Repositories Use It

A Terraform repository adds one job to its pipeline that calls `.github/workflows/terraform-policy.yaml` at a release tag. The job lints and scans the configuration and, when the pipeline uploads its plan as JSON, evaluates the plan policies. The README shows the snippet and the inputs.

## How Policies Change

Policies change through commits to this repository. Every policy has unit tests, and fixtures pin down what is reported; the pipeline runs both on every push. Callers pin a release tag, so a change reaches them when the tag moves.

## Owner

These policies are owned by **${{ values.owner }}**.
