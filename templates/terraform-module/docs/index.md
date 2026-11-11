# Terraform Module Template

Creates a repository with a reusable Terraform module for AWS, Azure, Google
Cloud or all three.

## What You Get

- A root module that switches eight building blocks on and off with `enable_*`
  variables: network, security, storage, observability, compute, database,
  Kubernetes and serverless.
- One submodule per building block and cloud, each usable on its own, each
  with its own tests and an example variables file.
- `examples/complete`, a runnable configuration that calls the module.
- Tests written for `terraform test` that plan against mocked providers, so
  they need no cloud account.
- A GitHub Actions pipeline that checks formatting, validates, lints with
  TFLint, runs the tests and scans with Trivy on every push. It needs no
  secrets and passes on the first push.
- A catalog entry and TechDocs.

## Form Fields

| Field                        | Effect                                                          |
| ---------------------------- | --------------------------------------------------------------- |
| Module Name                  | Repository and catalog name; must start with `terraform-`       |
| Description                  | Catalog description and documentation                           |
| Owner                        | Owner of the catalog entry                                      |
| Cloud Provider               | Which submodules, providers and example the repository contains |
| Terraform Version Constraint | `required_version` of the module and its example                |

## After Creation

```bash
terraform init -backend=false
terraform validate
terraform test
```

Use the module from another configuration:

```hcl
module "platform" {
  source = "github.com/<owner>/<repository>"

  project_name = "billing"
  environment  = "dev"
}
```
