#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/defaults/hypr" "$root/bin"
printf 'default\n' >"$root/defaults/hypr/monitors.lua"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*"\n' >"$root/bin/scaling"
chmod +x "$root/bin/scaling"

HOME="$root/home" XDG_CONFIG_HOME="$root/config" OMARCHY_CONFIG_ROOT="$root/defaults" \
  OMARCHY_SCALING_COMMAND="$root/bin/scaling" \
  "$repo/files/usr/libexec/obsidian-blue/omarchy-adapters/omarchy-hyprland-monitor-scaling" 1.25 | \
  grep -Fqx 1.25
grep -Fqx default "$root/config/omarchy/hypr/monitors.lua"

printf 'custom\n' >"$root/config/omarchy/hypr/monitors.lua"
HOME="$root/home" XDG_CONFIG_HOME="$root/config" OMARCHY_CONFIG_ROOT="$root/defaults" \
  OMARCHY_SCALING_COMMAND="$root/bin/scaling" \
  "$repo/files/usr/libexec/obsidian-blue/omarchy-adapters/omarchy-hyprland-monitor-scaling" up >/dev/null
grep -Fqx custom "$root/config/omarchy/hypr/monitors.lua"
