# Remote state in Google Cloud Storage. The bucket and prefix are passed with
# -backend-config by the workflow:
#   terraform init -backend-config="bucket=<bucket>" -backend-config="prefix=<name>/<environment>"
terraform {
  backend "gcs" {}
}
