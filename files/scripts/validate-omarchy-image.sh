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
  /usr/share/omarchy/themes/tokyo-night/colors.toml \
  /etc/profile.d/omarchy.sh \
  /etc/bashrc.d/99-omarchy.sh \
  /etc/skel/.local/state/obsidian-blue/quattro-4.0.0-image-config-v2 \
  /usr/share/wayland-sessions/omarchy.desktop \
  /usr/share/applications/Basecamp.desktop \
  /usr/share/applications/Alacritty.desktop \
  /usr/share/nautilus-python/extensions/localsend.py; do
  [[ -e "$path" ]] || fail "missing path: $path"
done

for session in omarchy.desktop hyprland.desktop hyprland-uwsm.desktop; do
  grep -Fqx 'Exec=/usr/bin/obsidian-blue-quattro-session' \
    "/usr/share/wayland-sessions/$session" || fail "session bypass remains: $session"
done

for path in /etc/skel/.config/hypr /etc/skel/.config/omarchy /etc/skel/.config/waybar \
  /etc/skel/.local/share/omadora; do
  [[ ! -e "$path" ]] || fail "user config default remains: $path"
done

for unit in bt-agent.service omarchy-recover-internal-monitor.service omarchy-sleep-lock.service \
  omarchy-migrate-notify.service omarchy-fcitx5.service omarchy-crash-watch.service; do
  [[ -f "/usr/lib/systemd/user/$unit" ]] || fail "missing user unit: $unit"
done

[[ ! -e /etc/sddm.conf.d/theme.conf ]] || fail "inherited SDDM theme override remains"
grep -Fqx 'Current=omarchy' /etc/sddm.conf.d/10-theme.conf || fail "Omarchy SDDM theme is inactive"
grep -Fq '$OMARCHY_PATH/config/?.lua' /usr/bin/obsidian-blue-quattro-session || \
  fail "baked Lua config path is absent"
grep -Fq '$OMARCHY_PATH/icon.txt' /usr/bin/omarchy-launch-about || fail "About branding has no fallback"
grep -Fq '$OMARCHY_PATH/logo.txt' /usr/bin/omarchy-screensaver || fail "screensaver has no fallback"
fc-match 'JetBrainsMono Nerd Font' --format '%{family}\n' | \
  grep -Fq 'JetBrainsMono Nerd Font' || fail "JetBrainsMono Nerd Font is absent"

home="$(mktemp -d)"
runtime="$(mktemp -d)"
chmod 700 "$runtime"
trap 'rm -rf "$home" "$runtime"' EXIT
HOME="$home" OMARCHY_PATH=/usr/share/omarchy \
  XDG_RUNTIME_DIR="$runtime" \
  LUA_PATH='/usr/share/omarchy/config/?.lua;;' \
  Hyprland --i-am-really-stupid --verify-config \
    --config /usr/share/omarchy/config/hypr/hyprland.lua >/dev/null

bash -n /usr/bin/obsidian-blue-quattro-session /usr/libexec/obsidian-blue/quattro-migrate \
  /usr/bin/omarchy-refresh-applications
echo "Omarchy Quattro image validated."
