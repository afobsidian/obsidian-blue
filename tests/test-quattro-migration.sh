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
  "$home/.local/share/applications" "$defaults/hypr" "$defaults/kitty" "$apps" "$omarchy/migrations"
printf 'old\n' >"$home/.config/hypr/value"
printf 'legacy\n' >"$home/.config/omadora/value"
printf 'new\n' >"$defaults/hypr/value"
printf 'kitty\n' >"$defaults/kitty/value"
printf 'desktop\n' >"$apps/Test.desktop"
touch "$omarchy/migrations/001.sh"

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" \
  OMARCHY_PATH="$omarchy" OMARCHY_SKIP_THEME=1 \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"

test "$(cat "$home/.config/hypr/value")" = new
test "$(cat "$home/.config/kitty/value")" = kitty
test ! -e "$home/.config/omadora"
test -f "$home/.local/state/obsidian-blue/quattro-4.0.0"
test -f "$home/.local/state/omarchy/migrations/001.sh"
test "$(find "$home/.local/state/obsidian-blue/backups" -path '*/config/hypr/value' -exec cat {} \;)" = old

printf 'mutable\n' >"$home/.config/hypr/value"
HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" \
  OMARCHY_PATH="$omarchy" OMARCHY_SKIP_THEME=1 \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/value")" = mutable

printf 'broken\n' >"$defaults/hypr/value"
mkdir -p "$home/.config/omadora"
printf 'legacy-again\n' >"$home/.config/omadora/value"
if HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_VERSION=4.0.1 \
  OMARCHY_CONFIG_ROOT="$defaults" \
  OMARCHY_APPLICATIONS_ROOT="$apps" OMARCHY_PATH="$root/missing" \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate" 2>/dev/null; then
  exit 1
fi
test "$(cat "$home/.config/hypr/value")" = mutable
test "$(cat "$home/.config/omadora/value")" = legacy-again
test ! -e "$home/.local/state/obsidian-blue/quattro-4.0.1"
