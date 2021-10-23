#!/usr/bin/env bash

set -euo pipefail

kbld_version="${1:-0.31.0}"
base_url="${2:-https://github.com/vmware-tanzu/carvel-kbld/releases/download}"

curl -L "${base_url}/v${kbld_version}/kbld-linux-amd64" > kbld
chmod +x kbld
mv kbld /usr/local/bin

