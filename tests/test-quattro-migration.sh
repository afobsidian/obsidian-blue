#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
home="$root/home"
defaults="$root/defaults"
apps="$root/apps"
omarchy="$root/omarchy"
mkdir -p "$home/.config/hypr" "$home/.config/omadora" "$home/.local/share/omadora" \
  "$home/.config/waybar" "$home/.config/systemd/user" "$home/.config/unrelated" \
  "$home/.local/share/applications" "$home/.local/state/omarchy/done" \
  "$defaults/hypr" "$defaults/kitty" "$apps" "$omarchy/migrations"
printf 'old\n' >"$home/.config/hypr/value"
printf 'legacy\n' >"$home/.config/omadora/value"
printf 'waybar\n' >"$home/.config/waybar/value"
printf 'unit\n' >"$home/.config/systemd/user/omadora-session.target"
printf 'keep\n' >"$home/.config/unrelated/value"
printf 'done\n' >"$home/.local/state/omarchy/done/first-run-user"
printf 'new\n' >"$defaults/hypr/value"
printf 'kitty\n' >"$defaults/kitty/value"
printf 'desktop\n' >"$apps/Test.desktop"
printf 'old desktop\n' >"$home/.local/share/applications/Test.desktop"
touch "$omarchy/migrations/001.sh"

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" \
  OMARCHY_PATH="$omarchy" OMARCHY_SKIP_THEME=1 \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"

test ! -e "$home/.config/hypr"
test ! -e "$home/.config/kitty"
test ! -e "$home/.config/omadora"
test ! -e "$home/.config/waybar"
test ! -e "$home/.config/systemd/user/omadora-session.target"
test ! -e "$home/.local/share/applications/Test.desktop"
test ! -e "$home/.local/state/omarchy/done/first-run-user"
test "$(cat "$home/.config/unrelated/value")" = keep
test -f "$home/.local/state/obsidian-blue/quattro-4.0.0-image-config-v2"
test -f "$home/.local/state/omarchy/migrations/001.sh"
test "$(find "$home/.local/state/obsidian-blue/backups" -path '*/.config/hypr/value' -exec cat {} \;)" = old
test "$(find "$home/.local/state/obsidian-blue/backups" -path '*/applications/Test.desktop' -exec cat {} \;)" = 'old desktop'

mkdir -p "$home/.config/hypr"
printf 'mutable\n' >"$home/.config/hypr/hyprland.lua"
HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" \
  OMARCHY_PATH="$omarchy" OMARCHY_SKIP_THEME=1 \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable

printf 'broken\n' >"$defaults/hypr/value"
mkdir -p "$home/.config/omadora"
printf 'legacy-again\n' >"$home/.config/omadora/value"
if HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_VERSION=4.0.1 \
  OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" OMARCHY_PATH="$root/missing" \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate" >/dev/null 2>&1; then
  exit 1
fi
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable
test "$(cat "$home/.config/omadora/value")" = legacy-again
test ! -e "$home/.local/state/obsidian-blue/quattro-4.0.1-image-config-v2"
