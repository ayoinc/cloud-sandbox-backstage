#!/usr/bin/env bash
# Copies the files that make up the published landing page into _site/, so
# that documentation and repository metadata are not deployed with it.
set -euo pipefail

rm -rf _site
mkdir _site
cp index.html _site/
cp -R css js images _site/
echo "Site assembled in _site/"
