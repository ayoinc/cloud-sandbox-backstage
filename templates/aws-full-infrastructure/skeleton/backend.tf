# The state lives in S3. The pipeline passes the bucket, key, region and lock
# table with -backend-config; see .github/actions/terraform-init/action.yml.
terraform {
  backend "s3" {}
}
