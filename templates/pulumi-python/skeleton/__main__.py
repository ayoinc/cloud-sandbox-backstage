"""Pulumi program: private log storage for the selected stack."""

import pulumi

from components.log_store import LogStore, LogStoreArgs

config = pulumi.Config()
project = pulumi.get_project()
stack = pulumi.get_stack()

retention_days = config.get_int("logRetentionDays")
force_destroy = config.get_bool("forceDestroy")

logs = LogStore(
    f"{project}-{stack}",
    LogStoreArgs(
        retention_days=90 if retention_days is None else retention_days,
        force_destroy=bool(force_destroy),
{%- if values.cloud == 'azure' %}
        geo_redundant=stack == "prod",
{%- endif %}
        tags={
            "project": project,
            "environment": stack,
            "owner": "${{ values.owner | replace('group:', '') | replace('user:', '') | replace('default/', '') }}",
            "managed-by": "pulumi",
        },
    ),
)
{%- if values.cloud == 'aws' %}

pulumi.export("bucketName", logs.bucket_name)
pulumi.export("keyArn", logs.key.arn)
{%- elif values.cloud == 'azure' %}

pulumi.export("resourceGroupName", logs.resource_group.name)
pulumi.export("storageAccountName", logs.account.name)
pulumi.export("containerName", logs.container.name)
{%- else %}

pulumi.export("bucketName", logs.bucket_name)
pulumi.export("keyId", logs.key.id)
{%- endif %}
