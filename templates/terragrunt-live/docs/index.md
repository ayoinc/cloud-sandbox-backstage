# Terragrunt Live Repository Template

This template creates a Terragrunt live repository for AWS, Azure or Google Cloud: the description of what is deployed in each environment and region, and a pipeline that validates and deploys it.

## What It Creates

- `root.hcl`, which generates the remote state backend and the provider for every unit
- A hierarchy `live/<environment>/<region>/` for `dev`, `staging` and `prod`, each with a `terragrunt.stack.hcl`
- A catalog of two units, `foundation` and `storage`, where the second depends on the first
- The OpenTofu modules behind the units, with tests that run against a mocked provider
- `mise.toml`, pinning OpenTofu and Terragrunt
- A GitHub Actions pipeline that signs in with OIDC

The repository uses the Terragrunt 1.x command line (`terragrunt run --all`, `terragrunt stack`, `terragrunt hcl`) and explicit stacks.

## Form Fields

| Field               | Description                                                 |
| ------------------- | ----------------------------------------------------------- |
| Project Name        | Prefix of resource names; at most 20 characters             |
| Description         | What the repository deploys                                 |
| Owner               | Team that owns the repository                               |
| Cloud Provider      | Selects the generated provider, the backend and the modules |
| Region              | First region of every environment                           |
| Repository Location | GitHub repository to create                                 |

## The Generated Repository

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, generates every stack and validates every unit with a local backend, runs the module tests and scans the modules with Trivy.

Plan and apply read the identity and the state bucket from the variables of the GitHub environment they target, so each environment can live in its own account, subscription or project. They are skipped until those variables exist. The README of the generated repository lists them.

A push to `main` deploys `dev`; `staging` and `prod` are deployed by running the workflow manually.

### Growing the Repository

Regions are added by copying a region directory, units by adding to the catalog and to the stack files. Once several teams or environments depend on the catalog, move it to its own repository and reference it by tag.

## Support

Contact the Platform Team for assistance.
