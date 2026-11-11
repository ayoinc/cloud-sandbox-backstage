# Remote state in Cloud Storage. The bucket and prefix are passed to
# `terraform init` with -backend-config; see README.md.
terraform {
  backend "gcs" {}
}
