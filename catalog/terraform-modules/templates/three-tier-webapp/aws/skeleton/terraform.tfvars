# Values chosen in the portal when this repository was created.

project_name = "${{ values.projectName }}"
environment  = "${{ values.environment }}"
region       = "${{ values.region }}"
vpc_cidr     = "${{ values.vpcCidr }}"

compute_type  = "${{ values.computeType }}"
instance_type = "${{ values.instanceType }}"
min_capacity  = ${{ values.minCapacity }}
max_capacity  = ${{ values.maxCapacity }}

database_engine         = "${{ values.databaseEngine }}"
database_instance_class = "${{ values.databaseInstanceClass }}"
multi_az                = ${{ values.multiAz | dump }}

enable_waf        = ${{ values.enableWaf | dump }}
enable_cloudfront = ${{ values.enableCloudfront | dump }}
