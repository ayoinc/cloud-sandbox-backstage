import { beforeAll, describe, expect, it } from "vitest";

import { LogStore } from "../src/logStore";
import { resolve, useMocks } from "./mocks";

// The mocks only have to be in place before the first resource is created.
beforeAll(() => {
  useMocks();
});
{%- if values.cloud == 'aws' %}

describe("LogStore", () => {
  it("blocks every form of public access", async () => {
    const store = new LogStore("unit-public", { retentionDays: 90 });
    const block = store.publicAccessBlock;

    expect(
      await resolve([
        block.blockPublicAcls,
        block.blockPublicPolicy,
        block.ignorePublicAcls,
        block.restrictPublicBuckets,
      ]),
    ).toEqual([true, true, true, true]);
  });

  it("versions the bucket and encrypts it with its own rotating key", async () => {
    const store = new LogStore("unit-crypt", { retentionDays: 90 });

    expect(await resolve(store.versioning.versioningConfiguration)).toMatchObject({
      status: "Enabled",
    });
    expect(await resolve(store.encryption.rules)).toMatchObject([
      {
        applyServerSideEncryptionByDefault: {
          sseAlgorithm: "aws:kms",
          kmsMasterKeyId: await resolve(store.key.arn),
        },
      },
    ]);
    expect(await resolve(store.key.enableKeyRotation)).toBe(true);
  });

  it("refuses requests that are not sent over TLS", async () => {
    const store = new LogStore("unit-tls", { retentionDays: 90 });
    const policy = JSON.parse(await resolve(store.policy.policy));

    expect(policy.Statement).toContainEqual(
      expect.objectContaining({
        Effect: "Deny",
        Condition: { Bool: { "aws:SecureTransport": "false" } },
      }),
    );
  });

  it("protects the bucket unless forceDestroy is set", async () => {
    const keep = new LogStore("unit-keep", { retentionDays: 90 });
    const drop = new LogStore("unit-drop", { retentionDays: 90, forceDestroy: true });

    expect(await resolve(keep.bucket.forceDestroy)).toBe(false);
    expect(await resolve(drop.bucket.forceDestroy)).toBe(true);
  });

  it("expires objects after the retention period", async () => {
    const store = new LogStore("unit-expiry", { retentionDays: 45 });

    expect(await resolve(store.lifecycle.rules)).toMatchObject([{ expiration: { days: 45 } }]);
  });

  it("records the tags on the bucket and the key", async () => {
    const store = new LogStore("unit-tags", { retentionDays: 90, tags: { environment: "dev" } });

    expect(await resolve(store.bucket.tags)).toEqual({ environment: "dev" });
    expect(await resolve(store.key.tags)).toEqual({ environment: "dev" });
  });

  it("rejects a retention period under 30 days", () => {
    expect(() => new LogStore("unit-short", { retentionDays: 7 })).toThrow(/at least 30/);
  });
});
{%- elif values.cloud == 'azure' %}

describe("LogStore", () => {
  it("creates a storage account that only Entra ID identities can reach", async () => {
    const store = new LogStore("unit-dev", { retentionDays: 90, tags: { environment: "dev" } });
    const account = store.account;

    expect(
      await resolve({
        publicBlobs: account.allowBlobPublicAccess,
        sharedKeys: account.allowSharedKeyAccess,
        httpsOnly: account.enableHttpsTrafficOnly,
        tls: account.minimumTlsVersion,
        sku: account.sku.name,
        tags: account.tags,
      }),
    ).toEqual({
      publicBlobs: false,
      sharedKeys: false,
      httpsOnly: true,
      tls: "TLS1_2",
      sku: "Standard_LRS",
      tags: { environment: "dev" },
    });
    expect(await resolve(account.networkRuleSet)).toMatchObject({ defaultAction: "Deny" });
    expect(await resolve(account.encryption)).toMatchObject({
      requireInfrastructureEncryption: true,
    });
  });

  it("keeps the account name within the limits of Azure", async () => {
    const store = new LogStore("a-very-long-project-name-prod", { retentionDays: 90 });

    // Pulumi appends 8 characters; the limit is 24.
    expect(await resolve(store.account.name)).toMatch(/^[a-z0-9]{3,16}$/);
  });

  it("is geo-redundant when asked", async () => {
    const store = new LogStore("unit-prod", { retentionDays: 365, geoRedundant: true });

    expect(await resolve(store.account.sku.name)).toBe("Standard_GRS");
  });

  it("keeps the container private", async () => {
    const store = new LogStore("unit-private", { retentionDays: 90 });

    expect(await resolve(store.container.publicAccess)).toBe("None");
  });

  it("versions blobs and expires them after the retention period", async () => {
    const store = new LogStore("unit-expiry", { retentionDays: 45 });

    expect(await resolve(store.blobService.isVersioningEnabled)).toBe(true);
    expect(await resolve(store.managementPolicy.policy)).toMatchObject({
      rules: [
        {
          definition: {
            actions: { baseBlob: { delete: { daysAfterModificationGreaterThan: 45 } } },
          },
        },
      ],
    });
  });

  it("rejects a retention period under 30 days", () => {
    expect(() => new LogStore("unit-short", { retentionDays: 7 })).toThrow(/at least 30/);
  });
});
{%- else %}

describe("LogStore", () => {
  it("creates a private, versioned bucket in the configured region", async () => {
    const store = new LogStore("unit-dev", { retentionDays: 90, tags: { environment: "dev" } });
    const bucket = store.bucket;

    expect(
      await resolve({
        location: bucket.location,
        uniformAccess: bucket.uniformBucketLevelAccess,
        publicAccessPrevention: bucket.publicAccessPrevention,
        versioning: bucket.versioning,
        labels: bucket.labels,
      }),
    ).toEqual({
      location: "${{ values.region }}",
      uniformAccess: true,
      publicAccessPrevention: "enforced",
      versioning: { enabled: true },
      labels: { environment: "dev" },
    });
  });

  it("encrypts the bucket with a rotating key that Cloud Storage may use", async () => {
    const store = new LogStore("unit-key", { retentionDays: 90 });

    expect(await resolve(store.bucket.encryption)).toEqual({
      defaultKmsKeyName: await resolve(store.key.id),
    });
    expect(await resolve(store.key.rotationPeriod)).toBe("7776000s");
    expect(await resolve(store.keyAccess.role)).toBe("roles/cloudkms.cryptoKeyEncrypterDecrypter");
    expect(await resolve(store.keyAccess.member)).toMatch(/^serviceAccount:service-/);
  });

  it("protects the bucket unless forceDestroy is set", async () => {
    const keep = new LogStore("unit-keep", { retentionDays: 90 });
    const drop = new LogStore("unit-drop", { retentionDays: 90, forceDestroy: true });

    expect(await resolve(keep.bucket.forceDestroy)).toBe(false);
    expect(await resolve(drop.bucket.forceDestroy)).toBe(true);
  });

  it("expires objects after the retention period", async () => {
    const store = new LogStore("unit-expiry", { retentionDays: 45 });

    expect(await resolve(store.bucket.lifecycleRules)).toMatchObject([
      { condition: { age: 45 } },
      { condition: { daysSinceNoncurrentTime: 30 } },
    ]);
  });

  it("rejects a retention period under 30 days", () => {
    expect(() => new LogStore("unit-short", { retentionDays: 7 })).toThrow(/at least 30/);
  });
});
{%- endif %}
