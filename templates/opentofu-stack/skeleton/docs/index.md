# ${{ values.name }}

${{ values.description }}

This repository holds an OpenTofu root stack for {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} in `${{ values.region }}`, deployed to three environments: `dev`, `staging` and `prod`.

## How It Is Deployed

A push to `main` runs the checks and, once the repository variables exist, plans and applies `dev`. `staging` and `prod` are deployed by running the **OpenTofu** workflow manually and choosing the environment and the action. Each environment has its own state object and its own values in `environments/<environment>.tfvars`.

## What It Creates
{%- if values.cloud == 'aws' %}

| File | Resources |
| --- | --- |
| `network.tofu` | VPC, private subnets across availability zones, a closed default security group, VPC flow logs |
| `storage.tofu` | Log bucket: versioned, private, TLS only, encrypted with its own rotating KMS key, with expiry rules |
{%- elif values.cloud == 'azure' %}

| File | Resources |
| --- | --- |
| `main.tofu` | Resource group, with an optional delete lock |
| `network.tofu` | Virtual network, private subnet without default outbound access, network security group |
| `storage.tofu` | Log storage account: Entra ID sign-in only, firewall closed by default, versioned, doubly encrypted, with expiry rules |
{%- else %}

| File | Resources |
| --- | --- |
| `network.tofu` | VPC network, private subnet with flow logs and Private Google Access, optional Cloud NAT |
| `storage.tofu` | Log bucket: versioned, public access prevented, encrypted with its own rotating Cloud KMS key, with expiry rules |
{%- endif %}

## State

State is stored in the backend configured in `backend.tofu` and encrypted on the client as configured in `encryption.tofu`: the bucket only ever holds ciphertext. Reading state therefore needs access to the bucket and permission to use the key.

## Changing the Stack

1. Edit the `.tofu` files or the values in `environments/`.
2. Run `tofu fmt -recursive` and `tofu test`; add a `run` block to `tests/stack.tftest.hcl` for new behaviour.
3. Push. The pipeline shows the plan in the run summary before it applies.

The README of the repository lists the repository variables and the one-time setup of the state bucket, the encryption key and the deployment identity.

## Owner

This stack is owned by **${{ values.owner }}**.
