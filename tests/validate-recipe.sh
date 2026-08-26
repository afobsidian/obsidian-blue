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
grep -Fq '        - curl' "$recipe"
grep -Fq '        - libcurl' "$recipe"
grep -Fq '        - curl-minimal' "$recipe"
grep -Fq '        - libcurl-minimal' "$recipe"
grep -Fq 'type: brew' "$recipe"
grep -Fq 'brew-analytics: false' "$recipe"
grep -Fq 'type: os-release' "$recipe"
grep -Fq 'DEFAULT_HOSTNAME: obsidian-blue' "$recipe"
grep -Fq 'scope: system' "$recipe"
grep -Fq 'md.obsidian.Obsidian' "$recipe"
! grep -Eqi 'omadora|monique|waybar-git|visual-studio-code|kubectl|helm' "$recipe"
grep -Fq '/usr/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
! grep -Fq '/usr/local/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'quattro-$version-image-config-v3' \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
grep -Fq 'omarchy-default-browser-select' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'omarchy-menu-monitors' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Open OBS Studio' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Open LocalSend' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'JETBRAINS_MONO_NERD_SHA256=' "$repo/files/scripts/omarchy-version.env"
test ! -e "$repo/.gitmodules"
grep -Fqx 'auth include login' "$repo/files/etc/pam.d/omarchy-lock-password"
grep -Fq 'omarchy-browser-launcher.patch' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Private browser binding is absent' "$repo/files/scripts/validate-omarchy-image.sh"
grep -Fq 'install-omarchy-nvim.sh' "$recipe"
grep -Fq 'OMARCHY_NVIM_SHA256=' "$repo/files/scripts/omarchy-nvim-version.env"

find "$repo/files" "$repo/scripts" "$repo/tests" -type f -name '*.sh' -print0 | \
  xargs -0 -n1 bash -n
