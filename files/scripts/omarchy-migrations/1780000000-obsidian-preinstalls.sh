#!/usr/bin/env bash
set -euo pipefail

# This image omits optional preinstalls; keep upstream migrations from reinstalling them.
mkdir -p "$HOME/.local/state/omarchy"
touch "$HOME/.local/state/omarchy/preinstalls-removed"
