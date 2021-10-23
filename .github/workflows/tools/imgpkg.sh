#!/usr/bin/env bash

set -euo pipefail

imgpkg_version="${1:-0.20.0}"
base_url="${2:-https://github.com/vmware-tanzu/carvel-imgpkg/releases/download}"

curl -L "${base_url}/v${imgpkg_version}/imgpkg-linux-amd64" > imgpkg
chmod +x imgpkg
mv imgpkg /usr/local/bin

