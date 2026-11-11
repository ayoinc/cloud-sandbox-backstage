{%- if values.cloud == 'aws' -%}
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

export interface LogStoreArgs {
  /** Days that log objects are kept before they are deleted. */
  retentionDays: number;
  /** Allow the bucket to be destroyed while it holds objects. */
  forceDestroy?: boolean;
  /** Tags recorded on every resource. */
  tags?: Record<string, string>;
}

/**
 * A private S3 bucket for logs: versioned, TLS only, encrypted with its own
 * rotating KMS key, with expiry rules.
 */
export class LogStore extends pulumi.ComponentResource {
  public readonly bucketName: pulumi.Output<string>;
  public readonly bucketArn: pulumi.Output<string>;
  public readonly keyArn: pulumi.Output<string>;

  public readonly key: aws.kms.Key;
  public readonly bucket: aws.s3.Bucket;
  public readonly publicAccessBlock: aws.s3.BucketPublicAccessBlock;
  public readonly versioning: aws.s3.BucketVersioning;
  public readonly encryption: aws.s3.BucketServerSideEncryptionConfiguration;
  public readonly lifecycle: aws.s3.BucketLifecycleConfiguration;
  public readonly policy: aws.s3.BucketPolicy;

  constructor(name: string, args: LogStoreArgs, opts?: pulumi.ComponentResourceOptions) {
    super("platform:storage:LogStore", name, {}, opts);

    if (args.retentionDays < 30) {
      throw new Error(`retentionDays must be at least 30, got ${args.retentionDays}`);
    }

    const parent = { parent: this };
    const tags = args.tags ?? {};

    this.key = new aws.kms.Key(
      `${name}-logs`,
      {
        description: `Encrypts the ${name} log bucket`,
        enableKeyRotation: true,
        deletionWindowInDays: 30,
        tags,
      },
      parent,
    );

    new aws.kms.Alias(
      `${name}-logs`,
      { name: `alias/${name}-logs`, targetKeyId: this.key.keyId },
      parent,
    );

    // Pulumi appends a random suffix, which keeps the name globally unique.
    this.bucket = new aws.s3.Bucket(
      `${name}-logs`,
      { forceDestroy: args.forceDestroy ?? false, tags },
      parent,
    );

    new aws.s3.BucketOwnershipControls(
      `${name}-logs`,
      { bucket: this.bucket.id, rule: { objectOwnership: "BucketOwnerEnforced" } },
      parent,
    );

    this.publicAccessBlock = new aws.s3.BucketPublicAccessBlock(
      `${name}-logs`,
      {
        bucket: this.bucket.id,
        blockPublicAcls: true,
        blockPublicPolicy: true,
        ignorePublicAcls: true,
        restrictPublicBuckets: true,
      },
      parent,
    );

    this.versioning = new aws.s3.BucketVersioning(
      `${name}-logs`,
      { bucket: this.bucket.id, versioningConfiguration: { status: "Enabled" } },
      parent,
    );

    this.encryption = new aws.s3.BucketServerSideEncryptionConfiguration(
      `${name}-logs`,
      {
        bucket: this.bucket.id,
        rules: [
          {
            bucketKeyEnabled: true,
            applyServerSideEncryptionByDefault: {
              sseAlgorithm: "aws:kms",
              kmsMasterKeyId: this.key.arn,
            },
          },
        ],
      },
      parent,
    );

    this.lifecycle = new aws.s3.BucketLifecycleConfiguration(
      `${name}-logs`,
      {
        bucket: this.bucket.id,
        rules: [
          {
            id: "expire-logs",
            status: "Enabled",
            filter: {},
            expiration: { days: args.retentionDays },
            noncurrentVersionExpiration: { noncurrentDays: 30 },
            abortIncompleteMultipartUpload: { daysAfterInitiation: 7 },
          },
        ],
      },
      { parent: this, dependsOn: [this.versioning] },
    );

    this.policy = new aws.s3.BucketPolicy(
      `${name}-logs`,
      {
        bucket: this.bucket.id,
        policy: pulumi.jsonStringify({
          Version: "2012-10-17",
          Statement: [
            {
              Sid: "DenyInsecureTransport",
              Effect: "Deny",
              Principal: "*",
              Action: "s3:*",
              Resource: [this.bucket.arn, pulumi.interpolate`${this.bucket.arn}/*`],
              Condition: { Bool: { "aws:SecureTransport": "false" } },
            },
          ],
        }),
      },
      { parent: this, dependsOn: [this.publicAccessBlock] },
    );

    this.bucketName = this.bucket.bucket;
    this.bucketArn = this.bucket.arn;
    this.keyArn = this.key.arn;

    this.registerOutputs({
      bucketName: this.bucketName,
      bucketArn: this.bucketArn,
      keyArn: this.keyArn,
    });
  }
}
{%- elif values.cloud == 'azure' -%}
import * as azure from "@pulumi/azure-native";
import * as pulumi from "@pulumi/pulumi";

export interface LogStoreArgs {
  /** Days that log blobs are kept before they are deleted. */
  retentionDays: number;
  /** Replicate the storage account to the paired region. */
  geoRedundant?: boolean;
  /** Accepted for parity with the other clouds; Azure soft delete protects the blobs instead. */
  forceDestroy?: boolean;
  /** Tags recorded on every resource. */
  tags?: Record<string, string>;
}

/**
 * A resource group with a private storage account for logs: Entra ID sign-in
 * only, no public blob access, versioned, doubly encrypted, with expiry rules.
 */
export class LogStore extends pulumi.ComponentResource {
  public readonly resourceGroupName: pulumi.Output<string>;
  public readonly storageAccountName: pulumi.Output<string>;
  public readonly containerName: pulumi.Output<string>;

  public readonly resourceGroup: azure.resources.ResourceGroup;
  public readonly account: azure.storage.StorageAccount;
  public readonly blobService: azure.storage.BlobServiceProperties;
  public readonly container: azure.storage.BlobContainer;
  public readonly managementPolicy: azure.storage.ManagementPolicy;

  constructor(name: string, args: LogStoreArgs, opts?: pulumi.ComponentResourceOptions) {
    super("platform:storage:LogStore", name, {}, opts);

    if (args.retentionDays < 30) {
      throw new Error(`retentionDays must be at least 30, got ${args.retentionDays}`);
    }

    const parent = { parent: this };
    const tags = args.tags ?? {};

    this.resourceGroup = new azure.resources.ResourceGroup(`rg-${name}`, { tags }, parent);

    // Storage account names allow 24 lowercase letters and digits. Pulumi
    // appends 8 random characters, which keeps the name unique across Azure.
    const accountName = `st${name.replace(/[^a-z0-9]/g, "")}`.slice(0, 16);

    // Shared keys are disabled: every caller signs in with Entra ID and needs
    // a Storage Blob Data role.
    this.account = new azure.storage.StorageAccount(
      accountName,
      {
        resourceGroupName: this.resourceGroup.name,
        kind: azure.storage.Kind.StorageV2,
        sku: {
          name: args.geoRedundant
            ? azure.storage.SkuName.Standard_GRS
            : azure.storage.SkuName.Standard_LRS,
        },
        minimumTlsVersion: azure.storage.MinimumTlsVersion.TLS1_2,
        enableHttpsTrafficOnly: true,
        allowBlobPublicAccess: false,
        allowSharedKeyAccess: false,
        defaultToOAuthAuthentication: true,
        // Closed by default: add virtual network or IP rules for the callers
        // that read the logs. Management of the account is unaffected.
        networkRuleSet: {
          defaultAction: azure.storage.DefaultAction.Deny,
          bypass: azure.storage.Bypass.AzureServices,
        },
        encryption: {
          keySource: azure.storage.KeySource.Microsoft_Storage,
          requireInfrastructureEncryption: true,
          services: { blob: { enabled: true, keyType: azure.storage.KeyType.Account } },
        },
        tags,
      },
      parent,
    );

    this.blobService = new azure.storage.BlobServiceProperties(
      `${name}-blob`,
      {
        resourceGroupName: this.resourceGroup.name,
        accountName: this.account.name,
        blobServicesName: "default",
        isVersioningEnabled: true,
        deleteRetentionPolicy: { enabled: true, days: 30 },
        containerDeleteRetentionPolicy: { enabled: true, days: 30 },
      },
      parent,
    );

    this.container = new azure.storage.BlobContainer(
      `${name}-logs`,
      {
        resourceGroupName: this.resourceGroup.name,
        accountName: this.account.name,
        containerName: "logs",
        publicAccess: azure.storage.PublicAccess.None,
      },
      parent,
    );

    this.managementPolicy = new azure.storage.ManagementPolicy(
      `${name}-expiry`,
      {
        resourceGroupName: this.resourceGroup.name,
        accountName: this.account.name,
        managementPolicyName: "default",
        policy: {
          rules: [
            {
              name: "expire-logs",
              enabled: true,
              type: azure.storage.RuleType.Lifecycle,
              definition: {
                filters: {
                  blobTypes: ["blockBlob", "appendBlob"],
                  prefixMatch: [pulumi.interpolate`${this.container.name}/`],
                },
                actions: {
                  baseBlob: {
                    delete: { daysAfterModificationGreaterThan: args.retentionDays },
                  },
                  version: { delete: { daysAfterCreationGreaterThan: 30 } },
                },
              },
            },
          ],
        },
      },
      parent,
    );

    this.resourceGroupName = this.resourceGroup.name;
    this.storageAccountName = this.account.name;
    this.containerName = this.container.name;

    this.registerOutputs({
      resourceGroupName: this.resourceGroupName,
      storageAccountName: this.storageAccountName,
      containerName: this.containerName,
    });
  }
}
{%- else -%}
import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";

export interface LogStoreArgs {
  /** Days that log objects are kept before they are deleted. */
  retentionDays: number;
  /** Allow the bucket to be destroyed while it holds objects. */
  forceDestroy?: boolean;
  /** Region of the bucket and of the key; defaults to gcp:region. */
  location?: string;
  /** Labels recorded on every resource. */
  tags?: Record<string, string>;
}

/**
 * A private Cloud Storage bucket for logs: versioned, public access prevented,
 * encrypted with its own rotating Cloud KMS key, with expiry rules.
 */
export class LogStore extends pulumi.ComponentResource {
  public readonly bucketName: pulumi.Output<string>;
  public readonly bucketUrl: pulumi.Output<string>;
  public readonly keyId: pulumi.Output<string>;

  public readonly key: gcp.kms.CryptoKey;
  public readonly keyAccess: gcp.kms.CryptoKeyIAMMember;
  public readonly bucket: gcp.storage.Bucket;

  constructor(name: string, args: LogStoreArgs, opts?: pulumi.ComponentResourceOptions) {
    super("platform:storage:LogStore", name, {}, opts);

    if (args.retentionDays < 30) {
      throw new Error(`retentionDays must be at least 30, got ${args.retentionDays}`);
    }

    const parent = { parent: this };
    const labels = args.tags ?? {};
    const location = args.location ?? new pulumi.Config("gcp").require("region");

    // Key rings cannot be deleted; destroying the stack leaves an empty one.
    const keyRing = new gcp.kms.KeyRing(`${name}-logs`, { location }, parent);

    this.key = new gcp.kms.CryptoKey(
      `${name}-logs`,
      { keyRing: keyRing.id, rotationPeriod: "7776000s", labels },
      parent,
    );

    // Cloud Storage encrypts with the key through its service agent.
    const serviceAgent = gcp.storage.getProjectServiceAccountOutput({}, parent);
    this.keyAccess = new gcp.kms.CryptoKeyIAMMember(
      `${name}-logs`,
      {
        cryptoKeyId: this.key.id,
        role: "roles/cloudkms.cryptoKeyEncrypterDecrypter",
        member: serviceAgent.member,
      },
      parent,
    );

    // Pulumi appends a random suffix, which keeps the name globally unique.
    this.bucket = new gcp.storage.Bucket(
      `${name}-logs`,
      {
        location,
        forceDestroy: args.forceDestroy ?? false,
        uniformBucketLevelAccess: true,
        publicAccessPrevention: "enforced",
        versioning: { enabled: true },
        encryption: { defaultKmsKeyName: this.key.id },
        lifecycleRules: [
          { condition: { age: args.retentionDays }, action: { type: "Delete" } },
          { condition: { daysSinceNoncurrentTime: 30 }, action: { type: "Delete" } },
        ],
        labels,
      },
      { parent: this, dependsOn: [this.keyAccess] },
    );

    this.bucketName = this.bucket.name;
    this.bucketUrl = this.bucket.url;
    this.keyId = this.key.id;

    this.registerOutputs({
      bucketName: this.bucketName,
      bucketUrl: this.bucketUrl,
      keyId: this.keyId,
    });
  }
}
{%- endif %}
