#!/usr/bin/env bash
set -euo pipefail

echo "Verify optional coding agents remain omitted from this image"
# The upstream migration requires Qwen declarations before checking the opt-out.
# Our image deliberately ships an empty tools table, so no shims need building.
test -f "${OMARCHY_MISE_CONFIG_PATH:-/etc/mise/conf.d/omarchy-tools.toml}"
tools="$(omarchy-mise-default-tools list)"
if [[ -n "$tools" ]]; then
  echo "Unexpected default mise tools; review the image preinstall policy." >&2
  exit 1
fi
