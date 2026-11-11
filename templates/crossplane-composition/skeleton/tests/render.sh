#!/usr/bin/env bash
# Render tests. Each input is run through the composition with `crossplane
# composition render`, which starts the functions in Docker: no cluster and no
# cloud account are involved. The result is validated against the schemas of
# the definition and the provider, then checked with yq.
set -euo pipefail

cd "$(dirname "$0")/.."

composition=package/apis/objectstore/composition.yaml
definition=package/apis/objectstore/definition.yaml
name_annotation='crossplane.io/composition-resource-name'
# Version of Crossplane whose composition engine renders the resources.
crossplane_version="${CROSSPLANE_VERSION:-v2.4.3}"
failed=0
mkdir -p _output

# render <input> <output>
render() {
  crossplane composition render "$1" "$composition" tests/functions.yaml \
    --include-full-xr --crossplane-version="$crossplane_version" > "$2"
}

# validate <rendered file>
validate() {
  crossplane resource validate "$definition,tests/providers.yaml" "$1" \
    --error-on-missing-schemas --skip-success-results
}

# expect_count <rendered file> <number of composed resources>
expect_count() {
  local actual
  actual=$(yq eval-all "[select(.metadata.annotations[\"$name_annotation\"] != null)] | length" "$1" 2>&1) || true
  if [ "$actual" = "$2" ]; then
    echo "  ok    number of composed resources: $2"
  else
    echo "  FAIL  composes $2 resources (got: $actual)"
    failed=1
  fi
}

# expect <rendered file> <composed resource> <yq expression> <description>
expect() {
  local actual
  actual=$(yq eval-all "select(.metadata.annotations[\"$name_annotation\"] == \"$2\") | $3" "$1" 2>&1) || true
  if [ "$actual" = "true" ]; then
    echo "  ok    $4"
  else
    echo "  FAIL  $4 (got: ${actual:-nothing})"
    failed=1
  fi
}
{%- if values.cloud == 'aws' %}

echo "examples/objectstore.yaml"
render examples/objectstore.yaml _output/example.yaml
validate _output/example.yaml
expect_count _output/example.yaml 5
expect _output/example.yaml bucket '.spec.forProvider.region == "${{ values.region }}"' "the bucket is created in the requested region"
expect _output/example.yaml bucket '.spec.forProvider.forceDestroy == false' "the bucket cannot be destroyed while it holds objects"
expect _output/example.yaml ownership '.spec.forProvider.rule.objectOwnership == "BucketOwnerEnforced"' "ACLs are disabled"
expect _output/example.yaml public-access-block '.spec.forProvider | (.blockPublicAcls and .blockPublicPolicy and .ignorePublicAcls and .restrictPublicBuckets)' "every form of public access is blocked"
expect _output/example.yaml encryption '.spec.forProvider.rule[0].applyServerSideEncryptionByDefault.sseAlgorithm == "aws:kms"' "objects are encrypted with KMS"
expect _output/example.yaml versioning '.spec.forProvider.versioningConfiguration.status == "Enabled"' "versioning is on"
expect _output/example.yaml versioning '.spec.forProvider.bucketSelector.matchControllerRef == true' "versioning selects the bucket of the same ObjectStore"

echo "tests/objectstore-suspended.yaml"
render tests/objectstore-suspended.yaml _output/suspended.yaml
validate _output/suspended.yaml
expect _output/suspended.yaml versioning '.spec.forProvider.versioningConfiguration.status == "Suspended"' "versioning: false suspends versioning"
expect _output/suspended.yaml bucket '.spec.providerConfigRef.name == "sandbox"' "the bucket uses the requested provider configuration"
expect _output/suspended.yaml encryption '.spec.providerConfigRef.name == "sandbox"' "so does every other resource"
{%- elif values.cloud == 'azure' %}

echo "examples/objectstore.yaml"
render examples/objectstore.yaml _output/example.yaml
validate _output/example.yaml
expect_count _output/example.yaml 3
expect _output/example.yaml resource-group '.spec.forProvider.location == "${{ values.region }}"' "the resource group is created in the requested region"
expect _output/example.yaml account '.spec.forProvider.allowNestedItemsToBePublic == false' "blobs cannot be made public"
expect _output/example.yaml account '.spec.forProvider.sharedAccessKeyEnabled == false' "only Entra ID identities can sign in"
expect _output/example.yaml account '.spec.forProvider.minTlsVersion == "TLS1_2"' "TLS 1.2 is the minimum"
expect _output/example.yaml account '.spec.forProvider.infrastructureEncryptionEnabled == true' "data is encrypted twice"
expect _output/example.yaml account '.spec.forProvider.blobProperties.versioningEnabled == true' "versioning is on"
expect _output/example.yaml container '.spec.forProvider.containerAccessType == "private"' "the container is private"

echo "tests/objectstore-suspended.yaml"
render tests/objectstore-suspended.yaml _output/suspended.yaml
validate _output/suspended.yaml
expect _output/suspended.yaml account '.spec.forProvider.blobProperties.versioningEnabled == false' "versioning: false turns versioning off"
expect _output/suspended.yaml account '(.metadata.annotations["crossplane.io/external-name"] // "") | test("^st[0-9a-f]{22}$")' "the account name is derived from the UID and fits the limits of Azure"
expect _output/suspended.yaml account '.spec.providerConfigRef.name == "sandbox"' "the account uses the requested provider configuration"
expect _output/suspended.yaml container '.spec.providerConfigRef.name == "sandbox"' "so does the container"
{%- else %}

echo "examples/objectstore.yaml"
render examples/objectstore.yaml _output/example.yaml
validate _output/example.yaml
expect_count _output/example.yaml 1
expect _output/example.yaml bucket '.spec.forProvider.location == "${{ values.region }}"' "the bucket is created in the requested region"
expect _output/example.yaml bucket '.spec.forProvider.publicAccessPrevention == "enforced"' "public access is prevented"
expect _output/example.yaml bucket '.spec.forProvider.uniformBucketLevelAccess == true' "access is uniform across the bucket"
expect _output/example.yaml bucket '.spec.forProvider.forceDestroy == false' "the bucket cannot be destroyed while it holds objects"
expect _output/example.yaml bucket '.spec.forProvider.versioning.enabled == true' "versioning is on"

echo "tests/objectstore-suspended.yaml"
render tests/objectstore-suspended.yaml _output/suspended.yaml
validate _output/suspended.yaml
expect _output/suspended.yaml bucket '.spec.forProvider.versioning.enabled == false' "versioning: false turns versioning off"
expect _output/suspended.yaml bucket '.spec.providerConfigRef.name == "sandbox"' "the bucket uses the requested provider configuration"
{%- endif %}

exit "$failed"
