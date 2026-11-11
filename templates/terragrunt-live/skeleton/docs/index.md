# ${{ values.name }}

${{ values.description }}

This repository describes the {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} infrastructure of `${{ values.name }}` with Terragrunt: one stack per environment (`dev`, `staging`, `prod`) and region (`${{ values.region }}`).

## How It Is Organised

| Path | Content |
| --- | --- |
| `root.hcl` | Generates the remote state backend and the provider for every unit |
| `live/<environment>/<region>/terragrunt.stack.hcl` | The units deployed in that environment and region |
| `catalog/units/` | Reusable units |
| `catalog/modules/` | The OpenTofu modules the units deploy |

## Units
{%- if values.cloud == 'aws' %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Rotating KMS key and its alias |
| `storage` | `catalog/modules/storage` | Log bucket: versioned, private, TLS only, encrypted with the key of `foundation` |
{%- elif values.cloud == 'azure' %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Resource group |
| `storage` | `catalog/modules/storage` | Log storage account in the resource group of `foundation`: Entra ID sign-in only, firewall closed by default, versioned, doubly encrypted |
{%- else %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Cloud KMS key ring and rotating key that Cloud Storage may use |
| `storage` | `catalog/modules/storage` | Log bucket: versioned, public access prevented, encrypted with the key of `foundation` |
{%- endif %}

## How It Is Deployed

A push to `main` runs the checks and, once the `dev` GitHub environment has its variables, plans and applies `dev`. `staging` and `prod` are deployed by running the **Terragrunt** workflow manually. Each unit has its own state object, keyed by its path: `live/<environment>/<region>/<unit>`.

The README of the repository lists the variables of the GitHub environments and the commands for working locally.

## Owner

This repository is owned by **${{ values.owner }}**.
