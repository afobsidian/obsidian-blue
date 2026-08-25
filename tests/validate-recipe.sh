#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
recipe="$repo/recipes/recipe.yml"

grep -Fq 'install-omarchy-quattro.sh' "$recipe"
grep -Fq 'podman-docker' "$recipe"
grep -Fq 'NetworkManager-tui' "$recipe"
grep -Fq 'tailscale' "$recipe"
grep -Fq 'libxkbcommon-utils' "$recipe"
grep -Fq 'perl-JSON-PP' "$recipe"
grep -Fq 'scope: system' "$recipe"
grep -Fq 'md.obsidian.Obsidian' "$recipe"
! grep -Eqi 'omadora|monique|waybar-git|visual-studio-code|kubectl|helm' "$recipe"
grep -Fq '/usr/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
! grep -Fq '/usr/local/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'quattro-$version-image-config-v2' \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
grep -Fq 'JETBRAINS_MONO_NERD_SHA256=' "$repo/files/scripts/omarchy-version.env"
test ! -e "$repo/.gitmodules"

find "$repo/files" "$repo/scripts" "$repo/tests" -type f -name '*.sh' -print0 | \
  xargs -0 -n1 bash -n
