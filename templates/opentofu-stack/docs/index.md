# OpenTofu Stack Template

This template creates a repository with an OpenTofu root stack for AWS, Azure or Google Cloud and a pipeline that validates, tests, scans and deploys it.

## What It Creates

- A network baseline and an encrypted, private log store in the chosen cloud
- Client-side encryption of state and plan files with the cloud's key service (AWS KMS, Azure Key Vault or Cloud KMS)
- A state backend configured from variables, with one state object per environment
- Variable files for `dev`, `staging` and `prod`
- Tests that run with `tofu test` against a mocked provider
- A GitHub Actions pipeline that signs in with OIDC

The stack uses features that exist only in OpenTofu (state encryption, variables in the backend block, the `enabled` meta-argument, `.tofu` files) and needs OpenTofu 1.13 or later.

## Form Fields

| Field               | Description                                            |
| ------------------- | ------------------------------------------------------ |
| Stack Name          | Prefix of every resource name; at most 24 characters   |
| Description         | What the stack provisions                              |
| Owner               | Team that owns the repository                          |
| Cloud Provider      | Selects the provider, the backend and the key provider |
| Region              | Region the stack is deployed to                        |
| Repository Location | GitHub repository to create                            |

## The Generated Repository

| Path                                       | Content                                                          |
| ------------------------------------------ | ---------------------------------------------------------------- |
| `*.tofu`                                   | Providers, backend, encryption, resources, variables and outputs |
| `environments/`                            | One variable file per environment                                |
| `tests/`                                   | Tests against a mocked provider                                  |
| `.github/workflows/opentofu.yaml`          | Pipeline                                                         |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml` | TechDocs and the catalog entity                                  |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, runs the tests and scans with Trivy. None of these needs a cloud account.

Plan and apply are skipped until the repository variables that identify the deployment identity, the state bucket and the state encryption key exist. They are variables rather than secrets because OIDC needs no stored credential. The README of the generated repository lists them for the chosen cloud and shows how to create the bucket, the key and the identity.

A push to `main` deploys `dev`. `staging` and `prod` are deployed by running the workflow manually; add required reviewers to those GitHub environments to gate them.

## Support

Contact the Platform Team for assistance.
