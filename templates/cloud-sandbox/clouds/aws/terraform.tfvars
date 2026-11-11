# Values chosen when this sandbox was created. Change them here and push to
# apply the change.
name        = "${{ values.name }}"
environment = "${{ values.environment }}"
region      = "${{ values.region }}"

vpc_cidr        = "${{ values.vpc_cidr }}"
public_subnets  = ${{ values.public_subnets }}
private_subnets = ${{ values.private_subnets }}

include_bastion = ${{ values.include_bastion | string | lower }}
include_eks     = ${{ values.include_eks | string | lower }}
include_rds     = ${{ values.include_rds | string | lower }}
