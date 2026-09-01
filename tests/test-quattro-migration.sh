#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
home="$root/home"
omarchy="$root/omarchy"
fake_bin="$root/bin"
mkdir -p "$home/.config/hypr" "$home/.config/omadora" "$home/.local/share/omadora" \
  "$home/.config/uwsm" "$home/.config/waybar" "$home/.config/systemd/user" "$home/.config/unrelated" \
  "$home/.local/share/applications" "$home/.local/state/omarchy/done" "$omarchy/migrations" "$fake_bin"
printf 'old\n' >"$home/.config/hypr/value"
printf 'legacy\n' >"$home/.config/omadora/value"
printf 'legacy uwsm\n' >"$home/.config/uwsm/env"
printf 'waybar\n' >"$home/.config/waybar/value"
printf 'unit\n' >"$home/.config/systemd/user/omadora-session.target"
printf 'keep\n' >"$home/.config/unrelated/value"
printf 'done\n' >"$home/.local/state/omarchy/done/first-run-user"
printf 'old desktop\n' >"$home/.local/share/applications/Test.desktop"
printf '%s\n' 'printf migrated >"$HOME/migrated"' >"$omarchy/migrations/001.sh"
printf '%s\n' 'pacman -S impossible' >"$omarchy/migrations/002.sh"
printf '%s\n' 'printf recovered >"$HOME/recovered"' >"$omarchy/migrations/1786782461.sh"
printf '%s\n' 'printf pacman-called >"$HOME/pacman-called"' >"$fake_bin/pacman"
printf '%s\n' '[[ "$2" == mise || "$2" == qt6-qtimageformats ]] && exit 0; exit 1' >"$fake_bin/rpm"
printf '%s\n' 'printf "%s\\n" "$*" >"$HOME/systemctl-called"' >"$fake_bin/systemctl"
chmod 755 "$fake_bin/pacman"
chmod 755 "$fake_bin/rpm"
chmod 755 "$fake_bin/systemctl"
mkdir -p "$home/.local/state/obsidian-blue" "$home/.local/state/omarchy/migrations"
touch "$home/.local/state/obsidian-blue/quattro-4.0.0-image-config-v3"
touch "$home/.local/state/omarchy/migrations/1786782461.sh"

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  PATH="$fake_bin:$PATH" "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"

test "$(cat "$home/.config/hypr/value")" = old
test "$(cat "$home/.config/omadora/value")" = legacy
test "$(cat "$home/.config/uwsm/env")" = 'legacy uwsm'
test "$(cat "$home/.config/waybar/value")" = waybar
test "$(cat "$home/.config/systemd/user/omadora-session.target")" = unit
test "$(cat "$home/.local/share/applications/Test.desktop")" = 'old desktop'
test "$(cat "$home/.local/state/omarchy/done/first-run-user")" = done
test "$(cat "$home/.config/unrelated/value")" = keep
test -f "$home/.local/state/obsidian-blue/quattro-4.0.0-image-config-v4"
test "$(cat "$home/systemctl-called")" = '--user enable omarchy-migrate-notify.service'
test ! -e "$home/migrated"

adapter_dir="$repo/files/usr/libexec/obsidian-blue/omarchy-adapters"
pending="$(HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  PATH="$fake_bin:$adapter_dir:$PATH" omarchy-migrate --pending)"
test "$pending" = $'001.sh\n002.sh\n1786782461.sh'
HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  PATH="$fake_bin:$adapter_dir:$PATH" omarchy-migrate
test -f "$home/migrated"
test -f "$home/pacman-called"
test -f "$home/recovered"
test -f "$home/.local/state/omarchy/migrations/001.sh"
test -f "$home/.local/state/omarchy/migrations/002.sh"
PATH="$fake_bin:$adapter_dir:$PATH" omarchy-pkg-present mise-bin
PATH="$fake_bin:$adapter_dir:$PATH" omarchy-pkg-add qt6-imageformats

printf 'mutable\n' >"$home/.config/hypr/hyprland.lua"
HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$omarchy" \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable

HOME="$home" XDG_STATE_HOME="$home/.local/state" OMARCHY_VERSION=4.0.1 \
  OMARCHY_PATH="$root/missing" "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
test "$(cat "$home/.config/hypr/hyprland.lua")" = mutable
test -f "$home/.local/state/obsidian-blue/quattro-4.0.1-image-config-v4"
