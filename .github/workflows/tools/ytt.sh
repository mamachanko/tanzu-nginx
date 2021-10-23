#!/usr/bin/env bash

set -euo pipefail

ytt_version="${1:-0.37.0}"
base_url="${2:-https://github.com/vmware-tanzu/carvel-ytt/releases/download}"

curl -L "${base_url}/v${ytt_version}/ytt-linux-amd64" > ytt
chmod +x ytt
mv ytt /usr/local/bin

