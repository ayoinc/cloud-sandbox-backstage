{%- if values.cloud == 'aws' -%}
"""Private, encrypted log storage on S3."""

from dataclasses import dataclass, field

import pulumi
import pulumi_aws as aws

MIN_RETENTION_DAYS = 30


@dataclass(frozen=True)
class LogStoreArgs:
    """Settings of a LogStore."""

    retention_days: int
    """Days that log objects are kept before they are deleted."""
    force_destroy: bool = False
    """Allow the bucket to be destroyed while it holds objects."""
    tags: dict[str, str] = field(default_factory=dict)
    """Tags recorded on every resource."""


class LogStore(pulumi.ComponentResource):
    """A private S3 bucket for logs.

    The bucket is versioned, refuses requests without TLS, is encrypted with
    its own rotating KMS key and expires objects after the retention period.
    """

    def __init__(
        self,
        name: str,
        args: LogStoreArgs,
        opts: pulumi.ResourceOptions | None = None,
    ) -> None:
        super().__init__("platform:storage:LogStore", name, None, opts)

        if args.retention_days < MIN_RETENTION_DAYS:
            msg = f"retention_days must be at least {MIN_RETENTION_DAYS}, got {args.retention_days}"
            raise ValueError(msg)

        child = pulumi.ResourceOptions(parent=self)

        self.key = aws.kms.Key(
            f"{name}-logs",
            description=f"Encrypts the {name} log bucket",
            enable_key_rotation=True,
            deletion_window_in_days=30,
            tags=args.tags,
            opts=child,
        )
        aws.kms.Alias(
            f"{name}-logs",
            name=f"alias/{name}-logs",
            target_key_id=self.key.key_id,
            opts=child,
        )

        # Pulumi appends a random suffix, which keeps the name globally unique.
        self.bucket = aws.s3.Bucket(
            f"{name}-logs",
            force_destroy=args.force_destroy,
            tags=args.tags,
            opts=child,
        )
        aws.s3.BucketOwnershipControls(
            f"{name}-logs",
            bucket=self.bucket.id,
            rule={"object_ownership": "BucketOwnerEnforced"},
            opts=child,
        )
        self.public_access_block = aws.s3.BucketPublicAccessBlock(
            f"{name}-logs",
            bucket=self.bucket.id,
            block_public_acls=True,
            block_public_policy=True,
            ignore_public_acls=True,
            restrict_public_buckets=True,
            opts=child,
        )
        self.versioning = aws.s3.BucketVersioning(
            f"{name}-logs",
            bucket=self.bucket.id,
            versioning_configuration={"status": "Enabled"},
            opts=child,
        )
        self.encryption = aws.s3.BucketServerSideEncryptionConfiguration(
            f"{name}-logs",
            bucket=self.bucket.id,
            rules=[
                {
                    "bucket_key_enabled": True,
                    "apply_server_side_encryption_by_default": {
                        "sse_algorithm": "aws:kms",
                        "kms_master_key_id": self.key.arn,
                    },
                }
            ],
            opts=child,
        )
        self.lifecycle = aws.s3.BucketLifecycleConfiguration(
            f"{name}-logs",
            bucket=self.bucket.id,
            rules=[
                {
                    "id": "expire-logs",
                    "status": "Enabled",
                    "filter": {},
                    "expiration": {"days": args.retention_days},
                    "noncurrent_version_expiration": {"noncurrent_days": 30},
                    "abort_incomplete_multipart_upload": {"days_after_initiation": 7},
                }
            ],
            opts=pulumi.ResourceOptions(parent=self, depends_on=[self.versioning]),
        )
        self.policy = aws.s3.BucketPolicy(
            f"{name}-logs",
            bucket=self.bucket.id,
            policy=pulumi.Output.json_dumps(
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "DenyInsecureTransport",
                            "Effect": "Deny",
                            "Principal": "*",
                            "Action": "s3:*",
                            "Resource": [
                                self.bucket.arn,
                                pulumi.Output.format("{0}/*", self.bucket.arn),
                            ],
                            "Condition": {"Bool": {"aws:SecureTransport": "false"}},
                        }
                    ],
                }
            ),
            opts=pulumi.ResourceOptions(parent=self, depends_on=[self.public_access_block]),
        )

        self.bucket_name = self.bucket.bucket
        self.register_outputs({"bucketName": self.bucket_name, "keyArn": self.key.arn})
{%- elif values.cloud == 'azure' -%}
"""Private, encrypted log storage on Azure Storage."""

import re
from dataclasses import dataclass, field

import pulumi
import pulumi_azure_native as azure

MIN_RETENTION_DAYS = 30


@dataclass(frozen=True)
class LogStoreArgs:
    """Settings of a LogStore."""

    retention_days: int
    """Days that log blobs are kept before they are deleted."""
    geo_redundant: bool = False
    """Replicate the storage account to the paired region."""
    force_destroy: bool = False
    """Accepted for parity with the other clouds; soft delete protects the blobs instead."""
    tags: dict[str, str] = field(default_factory=dict)
    """Tags recorded on every resource."""


class LogStore(pulumi.ComponentResource):
    """A resource group with a private storage account for logs.

    The account accepts Entra ID sign-in only, refuses public blob access, has
    its firewall closed by default, is versioned and doubly encrypted, and
    expires blobs after the retention period.
    """

    def __init__(
        self,
        name: str,
        args: LogStoreArgs,
        opts: pulumi.ResourceOptions | None = None,
    ) -> None:
        super().__init__("platform:storage:LogStore", name, None, opts)

        if args.retention_days < MIN_RETENTION_DAYS:
            msg = f"retention_days must be at least {MIN_RETENTION_DAYS}, got {args.retention_days}"
            raise ValueError(msg)

        child = pulumi.ResourceOptions(parent=self)

        self.resource_group = azure.resources.ResourceGroup(
            f"rg-{name}",
            tags=args.tags,
            opts=child,
        )

        # Storage account names allow 24 lowercase letters and digits. Pulumi
        # appends 8 random characters, which keeps the name unique across Azure.
        account_name = ("st" + re.sub(r"[^a-z0-9]", "", name))[:16]

        # Shared keys are disabled: every caller signs in with Entra ID and
        # needs a Storage Blob Data role.
        self.account = azure.storage.StorageAccount(
            account_name,
            resource_group_name=self.resource_group.name,
            kind=azure.storage.Kind.STORAGE_V2,
            sku={
                "name": azure.storage.SkuName.STANDARD_GRS
                if args.geo_redundant
                else azure.storage.SkuName.STANDARD_LRS,
            },
            minimum_tls_version=azure.storage.MinimumTlsVersion.TLS1_2,
            enable_https_traffic_only=True,
            allow_blob_public_access=False,
            allow_shared_key_access=False,
            default_to_o_auth_authentication=True,
            # Closed by default: add virtual network or IP rules for the callers
            # that read the logs. Management of the account is unaffected.
            network_rule_set={
                "default_action": azure.storage.DefaultAction.DENY,
                "bypass": azure.storage.Bypass.AZURE_SERVICES,
            },
            encryption={
                "key_source": azure.storage.KeySource.MICROSOFT_STORAGE,
                "require_infrastructure_encryption": True,
                "services": {
                    "blob": {"enabled": True, "key_type": azure.storage.KeyType.ACCOUNT},
                },
            },
            tags=args.tags,
            opts=child,
        )
        self.blob_service = azure.storage.BlobServiceProperties(
            f"{name}-blob",
            resource_group_name=self.resource_group.name,
            account_name=self.account.name,
            blob_services_name="default",
            is_versioning_enabled=True,
            delete_retention_policy={"enabled": True, "days": 30},
            container_delete_retention_policy={"enabled": True, "days": 30},
            opts=child,
        )
        self.container = azure.storage.BlobContainer(
            f"{name}-logs",
            resource_group_name=self.resource_group.name,
            account_name=self.account.name,
            container_name="logs",
            public_access=azure.storage.PublicAccess.NONE,
            opts=child,
        )
        self.management_policy = azure.storage.ManagementPolicy(
            f"{name}-expiry",
            resource_group_name=self.resource_group.name,
            account_name=self.account.name,
            management_policy_name="default",
            policy={
                "rules": [
                    {
                        "name": "expire-logs",
                        "enabled": True,
                        "type": azure.storage.RuleType.LIFECYCLE,
                        "definition": {
                            "filters": {
                                "blob_types": ["blockBlob", "appendBlob"],
                                "prefix_match": [pulumi.Output.format("{0}/", self.container.name)],
                            },
                            "actions": {
                                "base_blob": {
                                    "delete": {
                                        "days_after_modification_greater_than": args.retention_days,
                                    },
                                },
                                "version": {"delete": {"days_after_creation_greater_than": 30}},
                            },
                        },
                    }
                ],
            },
            opts=child,
        )

        self.register_outputs(
            {
                "resourceGroupName": self.resource_group.name,
                "storageAccountName": self.account.name,
                "containerName": self.container.name,
            }
        )
{%- else -%}
"""Private, encrypted log storage on Cloud Storage."""

from dataclasses import dataclass, field

import pulumi
import pulumi_gcp as gcp

MIN_RETENTION_DAYS = 30


@dataclass(frozen=True)
class LogStoreArgs:
    """Settings of a LogStore."""

    retention_days: int
    """Days that log objects are kept before they are deleted."""
    force_destroy: bool = False
    """Allow the bucket to be destroyed while it holds objects."""
    location: str | None = None
    """Region of the bucket and of the key; defaults to gcp:region."""
    tags: dict[str, str] = field(default_factory=dict)
    """Labels recorded on every resource."""


class LogStore(pulumi.ComponentResource):
    """A private Cloud Storage bucket for logs.

    The bucket is versioned, prevents public access, is encrypted with its own
    rotating Cloud KMS key and expires objects after the retention period.
    """

    def __init__(
        self,
        name: str,
        args: LogStoreArgs,
        opts: pulumi.ResourceOptions | None = None,
    ) -> None:
        super().__init__("platform:storage:LogStore", name, None, opts)

        if args.retention_days < MIN_RETENTION_DAYS:
            msg = f"retention_days must be at least {MIN_RETENTION_DAYS}, got {args.retention_days}"
            raise ValueError(msg)

        child = pulumi.ResourceOptions(parent=self)
        location = args.location or pulumi.Config("gcp").require("region")

        # Key rings cannot be deleted; destroying the stack leaves an empty one.
        self.key_ring = gcp.kms.KeyRing(f"{name}-logs", location=location, opts=child)
        self.key = gcp.kms.CryptoKey(
            f"{name}-logs",
            key_ring=self.key_ring.id,
            rotation_period="7776000s",
            labels=args.tags,
            opts=child,
        )

        # Cloud Storage encrypts with the key through its service agent.
        service_agent = gcp.storage.get_project_service_account_output(
            opts=pulumi.InvokeOutputOptions(parent=self),
        )
        self.key_access = gcp.kms.CryptoKeyIAMMember(
            f"{name}-logs",
            crypto_key_id=self.key.id,
            role="roles/cloudkms.cryptoKeyEncrypterDecrypter",
            member=service_agent.member,
            opts=child,
        )

        # Pulumi appends a random suffix, which keeps the name globally unique.
        self.bucket = gcp.storage.Bucket(
            f"{name}-logs",
            location=location,
            force_destroy=args.force_destroy,
            uniform_bucket_level_access=True,
            public_access_prevention="enforced",
            versioning={"enabled": True},
            encryption={"default_kms_key_name": self.key.id},
            lifecycle_rules=[
                {"condition": {"age": args.retention_days}, "action": {"type": "Delete"}},
                {"condition": {"days_since_noncurrent_time": 30}, "action": {"type": "Delete"}},
            ],
            labels=args.tags,
            opts=pulumi.ResourceOptions(parent=self, depends_on=[self.key_access]),
        )

        self.bucket_name = self.bucket.name
        self.register_outputs({"bucketName": self.bucket_name, "keyId": self.key.id})
{%- endif %}
