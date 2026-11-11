# Pulumi Project (Python) Template

This template creates a repository with a Pulumi program in Python for AWS, Azure or Google Cloud and a pipeline that checks, previews and deploys it.

## What It Creates

- A Pulumi project with a typed configuration schema and a stack file for `dev`, `staging` and `prod`
- A `LogStore` component resource: private, versioned, encrypted log storage in the chosen cloud
- Unit tests that run against a mocked Pulumi engine, with no credentials
- A uv project with Ruff, mypy in strict mode and pytest
- A GitHub Actions pipeline that signs in to Pulumi Cloud and to the cloud with OIDC
- Instructions for moving configuration and credentials to Pulumi ESC

## Form Fields

| Field               | Description                                                                    |
| ------------------- | ------------------------------------------------------------------------------ |
| Project Name        | Name of the Pulumi project and prefix of resource names; at most 24 characters |
| Description         | What the project provisions                                                    |
| Owner               | Team that owns the repository                                                  |
| Cloud Provider      | Selects the provider package and the resources                                 |
| Region              | Region the stacks are deployed to                                              |
| Repository Location | GitHub repository to create                                                    |

## The Generated Repository

### Pipeline

The pipeline passes on the first push with nothing configured: it lints, type-checks and runs the unit tests. None of these needs a cloud account or a Pulumi account.

Preview and update are skipped until the repository variables exist: the Pulumi organisation and the identifiers of the cloud identity. They are variables rather than secrets because OIDC needs no stored credential. The README of the generated repository lists them for the chosen cloud.

A push to `main` updates the `dev` stack. `staging` and `prod` are updated by running the workflow manually; add required reviewers to those GitHub environments to gate them.

### State

Stacks are stored in Pulumi Cloud under the organisation named in the `PULUMI_ORG` repository variable. To use a self-managed backend instead, replace the Pulumi Cloud sign-in of the workflow with `pulumi login <backend-url>`.

## Support

Contact the Platform Team for assistance.
