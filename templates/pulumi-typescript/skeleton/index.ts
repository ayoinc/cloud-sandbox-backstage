import * as pulumi from "@pulumi/pulumi";

import { LogStore } from "./src/logStore";

const config = new pulumi.Config();
const project = pulumi.getProject();
const stack = pulumi.getStack();

const logs = new LogStore(`${project}-${stack}`, {
  retentionDays: config.getNumber("logRetentionDays", { min: 30 }) ?? 90,
  forceDestroy: config.getBoolean("forceDestroy") ?? false,
{%- if values.cloud == 'azure' %}
  geoRedundant: stack === "prod",
{%- endif %}
  tags: {
    project,
    environment: stack,
    owner: "${{ values.owner | replace('group:', '') | replace('user:', '') | replace('default/', '') }}",
    "managed-by": "pulumi",
  },
});
{%- if values.cloud == 'aws' %}

export const bucketName = logs.bucketName;
export const keyArn = logs.keyArn;
{%- elif values.cloud == 'azure' %}

export const resourceGroupName = logs.resourceGroupName;
export const storageAccountName = logs.storageAccountName;
export const containerName = logs.containerName;
{%- else %}

export const bucketName = logs.bucketName;
export const keyId = logs.keyId;
{%- endif %}
