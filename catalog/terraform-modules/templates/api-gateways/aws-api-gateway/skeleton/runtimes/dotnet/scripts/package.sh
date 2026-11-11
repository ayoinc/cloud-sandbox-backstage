#!/usr/bin/env bash
# Writes the Lambda deployment package build/lambda.zip from the publish
# output of src/Api. File times, permissions and order are fixed so that
# unchanged sources built with the same .NET SDK give an identical archive
# and Terraform does not redeploy the function.
set -euo pipefail
cd "$(dirname "$0")/.."
export TZ=UTC

rm -rf build/publish build/lambda.zip
dotnet publish src/Api -c Release -r linux-x64 --self-contained false -o build/publish
find build/publish -exec touch -t 198001010000 {} +
chmod -R u=rwX,go=rX build/publish
(cd build/publish && find . -type f | LC_ALL=C sort | zip -X -@ ../lambda.zip)
rm -rf build/publish
# The hash is the one Lambda reports as CodeSha256 and Terraform compares.
echo "Wrote build/lambda.zip, sha256 $(openssl dgst -sha256 -binary build/lambda.zip | base64)"
