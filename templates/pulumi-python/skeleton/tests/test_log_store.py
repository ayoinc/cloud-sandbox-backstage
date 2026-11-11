"""Unit tests of the LogStore component, run against the mocks of conftest.py."""

from typing import Any

import pulumi
import pytest

from components.log_store import LogStore, LogStoreArgs

{%- if values.cloud == 'aws' %}


@pulumi.runtime.test
def test_bucket_blocks_public_access() -> pulumi.Output[None]:
    store = LogStore("unit-public", LogStoreArgs(retention_days=90))
    block = store.public_access_block

    def check(flags: list[Any]) -> None:
        assert all(flags)

    return pulumi.Output.all(
        block.block_public_acls,
        block.block_public_policy,
        block.ignore_public_acls,
        block.restrict_public_buckets,
    ).apply(check)


@pulumi.runtime.test
def test_bucket_is_versioned_and_encrypted_with_its_key() -> pulumi.Output[None]:
    store = LogStore("unit-crypt", LogStoreArgs(retention_days=90))

    def check(values: list[Any]) -> None:
        versioning, rules, key_arn, rotates = values
        assert versioning["status"] == "Enabled"
        default = rules[0]["apply_server_side_encryption_by_default"]
        assert default["sse_algorithm"] == "aws:kms"
        assert default["kms_master_key_id"] == key_arn
        assert rotates is True

    return pulumi.Output.all(
        store.versioning.versioning_configuration,
        store.encryption.rules,
        store.key.arn,
        store.key.enable_key_rotation,
    ).apply(check)


@pulumi.runtime.test
def test_bucket_refuses_requests_without_tls() -> pulumi.Output[None]:
    store = LogStore("unit-tls", LogStoreArgs(retention_days=90))

    def check(policy: Any) -> None:
        assert '"aws:SecureTransport": "false"' in policy
        assert '"Effect": "Deny"' in policy

    return store.policy.policy.apply(check)


@pulumi.runtime.test
def test_bucket_is_protected_unless_force_destroy_is_set() -> pulumi.Output[None]:
    keep = LogStore("unit-keep", LogStoreArgs(retention_days=90))
    drop = LogStore("unit-drop", LogStoreArgs(retention_days=90, force_destroy=True))

    def check(values: list[Any]) -> None:
        assert values == [False, True]

    return pulumi.Output.all(keep.bucket.force_destroy, drop.bucket.force_destroy).apply(check)


@pulumi.runtime.test
def test_objects_expire_after_the_retention_period() -> pulumi.Output[None]:
    store = LogStore("unit-expiry", LogStoreArgs(retention_days=45))

    def check(rules: Any) -> None:
        assert rules[0]["expiration"]["days"] == 45

    return store.lifecycle.rules.apply(check)


def test_short_retention_is_rejected() -> None:
    with pytest.raises(ValueError, match="at least 30"):
        LogStore("unit-short", LogStoreArgs(retention_days=7))
{%- elif values.cloud == 'azure' %}


@pulumi.runtime.test
def test_account_admits_entra_id_identities_only() -> pulumi.Output[None]:
    store = LogStore("unit-dev", LogStoreArgs(retention_days=90))
    account = store.account

    def check(values: list[Any]) -> None:
        public_blobs, shared_keys, https_only, tls, encryption, sku, firewall = values
        assert public_blobs is False
        assert shared_keys is False
        assert https_only is True
        assert tls == "TLS1_2"
        assert encryption["require_infrastructure_encryption"] is True
        assert sku["name"] == "Standard_LRS"
        assert firewall["default_action"] == "Deny"

    return pulumi.Output.all(
        account.allow_blob_public_access,
        account.allow_shared_key_access,
        account.enable_https_traffic_only,
        account.minimum_tls_version,
        account.encryption,
        account.sku,
        account.network_rule_set,
    ).apply(check)


@pulumi.runtime.test
def test_account_name_fits_the_limits_of_azure() -> pulumi.Output[None]:
    store = LogStore("a-very-long-project-name-prod", LogStoreArgs(retention_days=90))

    def check(name: Any) -> None:
        # Pulumi appends 8 characters; the limit is 24.
        assert name.isalnum()
        assert name.islower()
        assert len(name) <= 16

    return store.account.name.apply(check)


@pulumi.runtime.test
def test_account_is_geo_redundant_when_asked() -> pulumi.Output[None]:
    store = LogStore("unit-prod", LogStoreArgs(retention_days=365, geo_redundant=True))

    def check(sku: Any) -> None:
        assert sku["name"] == "Standard_GRS"

    return store.account.sku.apply(check)


@pulumi.runtime.test
def test_blobs_are_versioned_and_expire() -> pulumi.Output[None]:
    store = LogStore("unit-expiry", LogStoreArgs(retention_days=45))

    def check(values: list[Any]) -> None:
        versioned, policy = values
        assert versioned is True
        delete = policy["rules"][0]["definition"]["actions"]["base_blob"]["delete"]
        assert delete["days_after_modification_greater_than"] == 45

    return pulumi.Output.all(
        store.blob_service.is_versioning_enabled,
        store.management_policy.policy,
    ).apply(check)


def test_short_retention_is_rejected() -> None:
    with pytest.raises(ValueError, match="at least 30"):
        LogStore("unit-short", LogStoreArgs(retention_days=7))
{%- else %}


@pulumi.runtime.test
def test_bucket_is_private_and_versioned() -> pulumi.Output[None]:
    store = LogStore("unit-dev", LogStoreArgs(retention_days=90))
    bucket = store.bucket

    def check(values: list[Any]) -> None:
        location, uniform, prevention, versioning = values
        assert location == "${{ values.region }}"
        assert uniform is True
        assert prevention == "enforced"
        assert versioning["enabled"] is True

    return pulumi.Output.all(
        bucket.location,
        bucket.uniform_bucket_level_access,
        bucket.public_access_prevention,
        bucket.versioning,
    ).apply(check)


@pulumi.runtime.test
def test_bucket_is_encrypted_with_a_rotating_key() -> pulumi.Output[None]:
    store = LogStore("unit-key", LogStoreArgs(retention_days=90))

    def check(values: list[Any]) -> None:
        encryption, key_id, rotation, role, member = values
        assert encryption["default_kms_key_name"] == key_id
        assert rotation == "7776000s"
        assert role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        assert member.startswith("serviceAccount:service-")

    return pulumi.Output.all(
        store.bucket.encryption,
        store.key.id,
        store.key.rotation_period,
        store.key_access.role,
        store.key_access.member,
    ).apply(check)


@pulumi.runtime.test
def test_bucket_is_protected_unless_force_destroy_is_set() -> pulumi.Output[None]:
    keep = LogStore("unit-keep", LogStoreArgs(retention_days=90))
    drop = LogStore("unit-drop", LogStoreArgs(retention_days=90, force_destroy=True))

    def check(values: list[Any]) -> None:
        assert values == [False, True]

    return pulumi.Output.all(keep.bucket.force_destroy, drop.bucket.force_destroy).apply(check)


@pulumi.runtime.test
def test_objects_expire_after_the_retention_period() -> pulumi.Output[None]:
    store = LogStore("unit-expiry", LogStoreArgs(retention_days=45, location="${{ values.region }}"))

    def check(rules: Any) -> None:
        assert rules[0]["condition"]["age"] == 45
        assert rules[1]["condition"]["days_since_noncurrent_time"] == 30

    return store.bucket.lifecycle_rules.apply(check)


def test_short_retention_is_rejected() -> None:
    with pytest.raises(ValueError, match="at least 30"):
        LogStore("unit-short", LogStoreArgs(retention_days=7))
{%- endif %}
