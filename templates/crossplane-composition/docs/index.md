# Crossplane Composition Template

This template creates a repository with a Crossplane v2 configuration: an API of your own, the composition that fulfils it on AWS, Azure or Google Cloud, and tests that render the composition without a cluster.

## What It Creates

- A composite resource definition (`apiextensions.crossplane.io/v2`, namespaced) for an `ObjectStore` API in your API group
- A composition in pipeline mode that uses `function-patch-and-transform` and `function-auto-ready` to build private, encrypted object storage from namespaced managed resources
- An example ObjectStore; in Crossplane v2 this replaces the claim
- Render tests: `crossplane composition render`, schema validation against the provider and field checks
- The configuration package metadata with pinned dependencies
- A GitHub Actions pipeline that tests, builds and, on a version tag, publishes the package to the GitHub container registry

## Form Fields

| Field               | Description                                                      |
| ------------------- | ---------------------------------------------------------------- |
| Configuration Name  | Name of the package and of the repository                        |
| Description         | What API the configuration offers                                |
| Owner               | Team that owns the repository                                    |
| Cloud Provider      | Selects the provider and the managed resources                   |
| API Group           | DNS-style group of the new API, usually `platform.<your-domain>` |
| Region              | Default region of an ObjectStore                                 |
| Repository Location | GitHub repository to create                                      |

## The Generated Repository

| Path                                       | Content                                                                          |
| ------------------------------------------ | -------------------------------------------------------------------------------- |
| `package/`                                 | The configuration package: `crossplane.yaml`, the definition and the composition |
| `examples/`                                | An example ObjectStore                                                           |
| `tests/`                                   | Test inputs, pinned functions and providers, `render.sh`                         |
| `.github/workflows/ci.yaml`                | Pipeline                                                                         |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml` | TechDocs and the catalog entity                                                  |

### Pipeline

The pipeline needs no cluster, no cloud account and no secret. Functions run in Docker on the runner. A tag such as `v0.1.0` publishes `ghcr.io/<owner>/<repository>:v0.1.0` with the token of the workflow.

### Requirements of the Control Plane

Crossplane v2 or later. The provider is configured with a `ClusterProviderConfig` that uses workload identity; the README of the generated repository shows it for the chosen cloud.

## Support

Contact the Platform Team for assistance.
