# =============================================================================
# Hetzner Cloud Servers - Backend Configuration
# =============================================================================
# Terraform state lives in Hetzner Object Storage, through the S3-compatible API.
# The bucket, the key and the endpoint are supplied when initialising:
#
#   export AWS_ACCESS_KEY_ID=<access key>  AWS_SECRET_ACCESS_KEY=<secret key>
#   export AWS_ENDPOINT_URL_S3=<endpoint>
#   terraform init \
#     -backend-config="bucket=<state bucket>" \
#     -backend-config="key=<project>/<environment>/terraform.tfstate"
# =============================================================================

terraform {
  backend "s3" {
    # The region is not used by Hetzner Object Storage, but the backend requires one.
    region = "us-east-1"

    # Hetzner Object Storage is not AWS: skip the checks that call AWS-only APIs.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
