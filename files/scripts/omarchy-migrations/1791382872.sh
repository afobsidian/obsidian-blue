#!/usr/bin/env bash
set -euo pipefail

echo "Refresh mise shims while preserving user-managed tool launchers"
# Optional default tools are omitted, so retiring legacy wrappers would remove access.
mise reshim --system
mise reshim
