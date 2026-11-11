# ${{ values.name }}

${{ values.description }}

This repository holds a Pulumi program in Python that deploys to {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} in `${{ values.region }}`. Each environment is a stack: `dev`, `staging` and `prod`.

## What It Creates
{%- if values.cloud == 'aws' %}

`LogStore` is a component resource: a private S3 bucket for logs that is versioned, refuses requests without TLS, is encrypted with its own rotating KMS key and expires objects after the retention period.
{%- elif values.cloud == 'azure' %}

`LogStore` is a component resource: a resource group with a storage account for logs that accepts Entra ID sign-in only, refuses public blob access, has its firewall closed by default, is versioned and doubly encrypted, and expires blobs after the retention period.
{%- else %}

`LogStore` is a component resource: a private Cloud Storage bucket for logs that is versioned, prevents public access, is encrypted with its own rotating Cloud KMS key and expires objects after the retention period.
{%- endif %}

## How It Is Deployed

A push to `main` runs the checks and, once the repository variables exist, previews and updates the `dev` stack. `staging` and `prod` are updated by running the **Pulumi** workflow manually and choosing the stack. State lives in Pulumi Cloud; the pipeline signs in with OIDC.

## Changing It

1. Edit the program or the configuration in `Pulumi.<stack>.yaml`.
2. Run the checks and the unit tests (`uv run ruff check . && uv run pytest`).
3. Push. The preview is shown in the run summary before the update.

The README of the repository lists the repository variables, the configuration keys and how to move configuration and credentials to Pulumi ESC.

## Owner

This project is owned by **${{ values.owner }}**.
