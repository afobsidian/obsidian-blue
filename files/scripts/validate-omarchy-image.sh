#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "Omarchy image validation failed: $*" >&2
  exit 1
}

for command in Hyprland flatpak hyprlock quickshell uwsm omarchy podman docker gh nvim fd rg nmtui \
  tailscale perf nc; do
  command -v "$command" >/dev/null || fail "missing command: $command"
done

for path in \
  /usr/share/omarchy/version \
  /usr/share/omarchy/shell/shell.qml \
  /usr/share/omarchy/config/hypr/hyprland.lua \
  /etc/skel/.config/hypr/hyprland.lua \
  /etc/skel/.local/state/obsidian-blue/quattro-4.0.0 \
  /usr/local/share/wayland-sessions/omarchy.desktop; do
  [[ -e "$path" ]] || fail "missing path: $path"
done

grep -Fqx 'Exec=/usr/bin/obsidian-blue-quattro-session' \
  /usr/local/share/wayland-sessions/omarchy.desktop || fail "session adapter is not installed"
[[ ! -e /etc/skel/.local/share/omadora ]] || fail "Omadora defaults remain"
[[ ! -e /etc/skel/.config/waybar ]] || fail "Waybar defaults remain"

bash -n /usr/bin/obsidian-blue-quattro-session /usr/libexec/obsidian-blue/quattro-migrate
echo "Omarchy Quattro image validated."
