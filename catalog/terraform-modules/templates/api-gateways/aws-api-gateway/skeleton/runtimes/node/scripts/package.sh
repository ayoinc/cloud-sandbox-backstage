#!/usr/bin/env bash
# Writes the Lambda deployment package build/lambda.zip from src/.
# File times and order are fixed so that unchanged sources give an identical
# archive and Terraform does not redeploy the function.
set -euo pipefail
cd "$(dirname "$0")/.."
export TZ=UTC

mkdir -p build
rm -f build/lambda.zip
find src -exec touch -t 198001010000 {} +
(cd src && find . -type f | LC_ALL=C sort | zip -X -q -@ ../build/lambda.zip)
echo "Wrote build/lambda.zip"
