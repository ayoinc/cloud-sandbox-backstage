# ${{ values.name }}

${{ values.description }}

This repository defines the `ObjectStore` API (`${{ values.apiGroup }}/v1alpha1`) for Crossplane v2 and the composition that fulfils it on {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %}.

## Requesting an Object Store

Create an ObjectStore in your namespace:

```yaml
apiVersion: ${{ values.apiGroup }}/v1alpha1
kind: ObjectStore
metadata:
  name: team-logs
  namespace: team-a
spec:
  parameters:
    region: ${{ values.region }}
```

`kubectl get objectstores -n team-a` shows whether it is ready and the name of the bucket.

## What You Get
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

## How It Changes

The definition and the composition live under `package/apis/objectstore/`. Every push renders the composition for the inputs under `examples/` and `tests/`, validates the result against the schemas of the provider and checks it. A pushed version tag publishes the configuration package, which control planes install.

The README of the repository covers the tests, the pipeline and the installation.

## Owner

This configuration is owned by **${{ values.owner }}**.
