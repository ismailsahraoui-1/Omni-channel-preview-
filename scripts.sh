#!/usr/bin/env bash
# Build a Netlify-ready zip for one space.
#   ./scripts.sh <name> <website-host>
#   ./scripts.sh acme colorful-demo-2-0-abc123xyz.colorful-demo.com
set -euo pipefail
name="${1:?name}"; host="${2:?website host}"
out="dist/$name"; mkdir -p "$out"
cp site/index.html "$out/index.html"
sed "s#WEBSITE_HOST#$host#" site/_redirects.template | grep -v '^#' > "$out/_redirects"
(cd "$out" && rm -f "../$name.zip" && zip -q "../$name.zip" index.html _redirects)
echo "Built dist/$name.zip — drag it onto https://app.netlify.com/drop"
