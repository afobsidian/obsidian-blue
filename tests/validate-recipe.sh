#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
recipe="$repo/recipes/recipe.yml"

grep -Fq 'install-omarchy-quattro.sh' "$recipe"
grep -Fq 'podman-docker' "$recipe"
grep -Fq 'NetworkManager-tui' "$recipe"
grep -Fq 'tailscale' "$recipe"
grep -Fq 'scope: system' "$recipe"
grep -Fq 'md.obsidian.Obsidian' "$recipe"
! grep -Eqi 'omadora|monique|waybar-git|visual-studio-code|kubectl|helm' "$recipe"
test ! -e "$repo/.gitmodules"

find "$repo/files" "$repo/scripts" "$repo/tests" -type f -name '*.sh' -print0 | \
  xargs -0 -n1 bash -n
