# ${{ values.name }}

${{ values.description }}

A [Crossplane](https://www.crossplane.io) v2 configuration that offers one API, `ObjectStore`, and fulfils it on {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %}. Teams create an ObjectStore in their namespace; Crossplane creates and keeps the cloud resources.

```yaml
apiVersion: ${{ values.apiGroup }}/v1alpha1
kind: ObjectStore
metadata:
  name: team-logs
  namespace: team-a
spec:
  parameters:
    region: ${{ values.region }}
    versioning: true
```

## Layout

| Path | Content |
| --- | --- |
| `package/crossplane.yaml` | The configuration package and what it depends on |
| `package/apis/objectstore/definition.yaml` | The composite resource definition (XRD): the schema of the API |
| `package/apis/objectstore/composition.yaml` | The composition: a pipeline of functions that builds the cloud resources |
| `examples/objectstore.yaml` | An ObjectStore as a team would write it |
| `tests/` | Inputs, pinned functions and providers, and the render tests |
| `.github/workflows/ci.yaml` | Pipeline |

Composite resources are namespaced in Crossplane v2, so there are no claims: the ObjectStore a team creates is the composite resource.

## The API

| Field | Default | Description |
| --- | --- | --- |
| `spec.parameters.region` | `${{ values.region }}` | Region the store is created in |
| `spec.parameters.versioning` | `true` | Keep earlier versions of overwritten and deleted objects |
| `spec.parameters.providerConfigName` | `default` | `ClusterProviderConfig` whose credentials create the store |
| `status.bucketName` | | Name of the bucket in the cloud |

## The Composition

The pipeline has two steps: `function-patch-and-transform` builds the resources below from base manifests and copies values between them and the ObjectStore, and `function-auto-ready` marks the ObjectStore ready once all of them are.
{%- if values.cloud == 'aws' %}

| Composed resource | Kind | Purpose |
| --- | --- | --- |
| `bucket` | `Bucket` | The S3 bucket |
| `ownership` | `BucketOwnershipControls` | Disables ACLs |
| `public-access-block` | `BucketPublicAccessBlock` | Blocks every form of public access |
| `encryption` | `BucketServerSideEncryptionConfiguration` | Encrypts objects with KMS |
| `versioning` | `BucketVersioning` | Follows `spec.parameters.versioning` |

All are namespaced managed resources of `s3.aws.m.upbound.io`, created in the namespace of the ObjectStore.
{%- elif values.cloud == 'azure' %}

| Composed resource | Kind | Purpose |
| --- | --- | --- |
| `resource-group` | `ResourceGroup` | Holds the storage account |
| `account` | `Account` | Storage account: Entra ID sign-in only, no public blobs, TLS 1.2, doubly encrypted; versioning follows `spec.parameters.versioning` |
| `container` | `Container` | A private container named `objects` |

All are namespaced managed resources of `azure.m.upbound.io` and `storage.azure.m.upbound.io`, created in the namespace of the ObjectStore. The storage account name is derived from the UID of the ObjectStore, because Azure allows only 24 lowercase letters and digits.
{%- else %}

| Composed resource | Kind | Purpose |
| --- | --- | --- |
| `bucket` | `Bucket` | Cloud Storage bucket: uniform access, public access prevented, old versions deleted after 90 days; versioning follows `spec.parameters.versioning` |

It is a namespaced managed resource of `storage.gcp.m.upbound.io`, created in the namespace of the ObjectStore.
{%- endif %}

## Tests

```bash
make test     # needs the Crossplane CLI, Docker and yq
```

`tests/render.sh` runs each input through the composition with `crossplane composition render`, validates the result against the schemas of the definition and the provider with `crossplane resource validate`, and checks single fields with yq. Nothing is created; no cluster or cloud account is involved. The rendered resources are written to `_output/`.

When you change the composition, add an `expect` line for the new behaviour, and a new input under `tests/` when it depends on a parameter.

## Pipeline

| Trigger | What runs |
| --- | --- |
| Push to any branch | Render tests and package build |
| Push of a tag `v*` | The same, then the package is published to `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:<tag>` |

Publishing uses the token of the workflow; no secret is needed.

## Installing in a Control Plane

The control plane needs Crossplane v2. Install the configuration; Crossplane installs the functions and the provider it depends on:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: ${{ values.name }}
spec:
  package: ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:v0.1.0
```

The package is private until you change its visibility; give the control plane a pull secret (`spec.packagePullSecrets`) or make the package public.

Then tell the provider how to sign in, without storing a key:
{%- if values.cloud == 'aws' %}

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: IRSA
```

`IRSA` uses the IAM role of the provider's service account on EKS; `PodIdentity` and `WebIdentity` work the same way. Grant that role the S3 permissions the composition needs and nothing else.
{%- elif values.cloud == 'azure' %}

```yaml
apiVersion: azure.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: OIDCTokenFile
  clientID: <client-id>
  tenantID: <tenant-id>
  subscriptionID: <subscription-id>
```

`OIDCTokenFile` uses workload identity on AKS: the provider's service account is federated with a managed identity, which needs `Contributor` on the subscription or on a scope you choose.
{%- else %}

```yaml
apiVersion: gcp.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  projectID: <project-id>
  credentials:
    source: InjectedIdentity
```

`InjectedIdentity` uses workload identity on GKE: the provider's Kubernetes service account impersonates a Google service account, which needs `roles/storage.admin` in the project.
{%- endif %}

Finally let teams use the API with ordinary Kubernetes RBAC: a `Role` in their namespace that allows `objectstores.${{ values.apiGroup }}`.

## Owner

This configuration is owned by **${{ values.owner }}**.
