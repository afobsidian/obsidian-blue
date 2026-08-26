#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
home="$root/home"
omarchy="$root/omarchy"
mkdir -p "$home/.config/hypr" "$home/.config/omadora" "$home/.local/share/omadora" \
  "$home/.config/uwsm" "$home/.config/waybar" "$home/.config/systemd/user" "$home/.config/unrelated" \
  "$home/.local/share/applications" "$home/.local/state/omarchy/done" "$omarchy/migrations"
printf 'old\n' >"$home/.config/hypr/value"
printf 'legacy\n' >"$home/.config/omadora/value"
printf 'legacy uwsm\n' >"$home/.config/uwsm/env"
printf 'waybar\n' >"$home/.config/waybar/value"
printf 'unit\n' >"$home/.config/systemd/user/omadora-session.target"
printf 'keep\n' >"$home/.config/unrelated/value"
printf 'done\n' >"$home/.local/state/omarchy/done/first-run-user"
printf 'old desktop\n' >"$home/.local/share/applications/Test.desktop"
touch "$omarchy/migrations/001.sh"

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"

test "$(cat "$home/.config/hypr/value")" = old
test "$(cat "$home/.config/omadora/value")" = legacy
test "$(cat "$home/.config/uwsm/env")" = 'legacy uwsm'
test "$(cat "$home/.config/waybar/value")" = waybar
test "$(cat "$home/.config/systemd/user/omadora-session.target")" = unit
test "$(cat "$home/.local/share/applications/Test.desktop")" = 'old desktop'
test "$(cat "$home/.local/state/omarchy/done/first-run-user")" = done
test "$(cat "$home/.config/unrelated/value")" = keep
test -f "$home/.local/state/obsidian-blue/quattro-4.0.0-image-config-v3"
test -f "$home/.local/state/omarchy/migrations/001.sh"

printf 'mutable\n' >"$home/.config/hypr/hyprland.lua"
HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_VERSION=4.0.1 \
  OMARCHY_PATH="$root/missing" "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable
test -f "$home/.local/state/obsidian-blue/quattro-4.0.1-image-config-v3"
