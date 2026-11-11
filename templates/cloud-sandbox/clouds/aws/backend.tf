# Remote state in S3. The bucket, key and region are passed to
# `terraform init` with -backend-config; see README.md.
terraform {
  backend "s3" {}
}
