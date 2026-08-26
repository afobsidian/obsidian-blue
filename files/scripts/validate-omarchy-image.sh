#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "Omarchy image validation failed: $*" >&2
  exit 1
}

for command in Hyprland flatpak hyprlock quickshell uwsm omarchy podman docker gh nvim fd rg nmtui xkbcli \
  tailscale perf nc curl; do
  command -v "$command" >/dev/null || fail "missing command: $command"
done

perl -MJSON::PP -e 1 || fail "missing Perl JSON::PP module"
curl_protocols="$(curl --version | sed -n 's/^Protocols: //p')"
grep -Eq '(^| )imap( |$)' <<<"$curl_protocols" || fail "curl IMAP support is absent"
grep -Eq '(^| )imaps( |$)' <<<"$curl_protocols" || fail "curl IMAPS support is absent"

for path in \
  /usr/share/omarchy/version \
  /usr/share/omarchy/shell/shell.qml \
  /usr/share/omarchy/config/hypr/hyprland.lua \
  /usr/share/omarchy/themes/tokyo-night/colors.toml \
  /usr/share/omarchy-nvim/config/lua/config/lazy.lua \
  /etc/skel/.config/nvim/lua/plugins/theme.lua \
  /usr/bin/omarchy-nvim-setup \
  /usr/bin/omarchy-default-browser-select \
  /usr/bin/omarchy-menu-monitors \
  /etc/profile.d/omarchy.sh \
  /etc/profile.d/99-omarchy-bash.sh \
  /etc/pam.d/omarchy-lock-password \
  /etc/skel/.local/state/obsidian-blue/quattro-4.0.0-image-config-v3 \
  /usr/share/wayland-sessions/omarchy.desktop \
  /usr/share/applications/Basecamp.desktop \
  /usr/share/applications/Alacritty.desktop \
  /usr/libexec/obsidian-blue/omarchy-hyprland-monitor-scaling \
  /usr/share/obsidian-blue/load-user-monitors.lua \
  /usr/share/nautilus-python/extensions/localsend.py; do
  [[ -e "$path" ]] || fail "missing path: $path"
done

grep -Fqx 'auth include login' /etc/pam.d/omarchy-lock-password || \
  fail "Fedora lock PAM stack is absent"
grep -Fqx 'NAME="obsidian-blue"' /usr/lib/os-release || fail "image name is not branded"
grep -Fqx 'DEFAULT_HOSTNAME="obsidian-blue"' /usr/lib/os-release || \
  fail "default hostname is not branded"
grep -Eq '^127\.0\.0\.1[[:space:]]+obsidian-blue[[:space:]]' /usr/etc/hosts || \
  fail "hostname is absent from hosts"
[[ ! -e /usr/lib/systemd/user/wayblue-update-verification.service ]] || \
  fail "Wayblue update notifier remains"
grep -Fqx 'SHELL=/bin/bash' /etc/default/useradd || fail "Bash is not the default user shell"
grep -Fq 'source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"' \
  /etc/profile.d/99-omarchy-bash.sh || \
  fail "Omarchy Bash environment is absent"

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
grep -Fq 'start-hyprland -- --config "$config"' /usr/bin/obsidian-blue-quattro-session || \
  fail "session launcher bypasses start-hyprland"
grep -Fq 'load-user-monitors.lua' /usr/share/omarchy/config/hypr/hyprland.lua || \
  fail "mutable monitor config is absent"
grep -Fq '/omarchy/hypr/monitors.lua' /usr/bin/omarchy-hyprland-monitor-scaling || \
  fail "monitor scaling does not persist in Omarchy config"
grep -Fq '$OMARCHY_PATH/icon.txt' /usr/bin/omarchy-launch-about || fail "About branding has no fallback"
grep -Fq '$OMARCHY_PATH/logo.txt' /usr/bin/omarchy-screensaver || fail "screensaver has no fallback"
grep -Fq 'omarchy = "browser"' /usr/share/omarchy/default/hypr/bindings/applications.lua || \
  fail "Browser binding is absent"
grep -Fq 'omarchy = "browser --private"' /usr/share/omarchy/default/hypr/bindings/applications.lua || \
  fail "Private browser binding is absent"
grep -Fq 'browser="chromium-browser.desktop"' /usr/bin/omarchy-launch-webapp || \
  fail "Fedora Chromium web-app fallback is absent"
test -L /etc/skel/.config/nvim/lua/plugins/theme.lua || fail "Neovim theme link is absent"
grep -Fq '"install.package": {"icon":"󰏗","label":"Flatpak"' \
  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || fail "Flatpak install menu is absent"
for route in learn.fedora setup.default.browser setup.monitors trigger.capture.screenrecord trigger.share; do
  grep -Fq "\"$route\"" /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
    fail "Fedora menu route is absent: $route"
done
grep -Fq 'Open OBS Studio' /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
  fail "OBS capture menu is absent"
grep -Fq 'Open LocalSend' /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
  fail "LocalSend menu is absent"
grep -Fq 'omarchy-cmd-present zed' /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
  fail "Zed editor detection is absent"
perl -0777 -pe 's/^\s*\/\/[^\n]*(\n|$)//gm; s/,(\s*[}\]])/$1/g' \
  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc | jq -e . >/dev/null || \
  fail "Omarchy menu JSONC is invalid"
if grep -Eq '"install\.(aur|style\.font|service|editor|terminal|browser|ai|gaming|windows|preinstalls)(\.|"|\})' \
  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
  grep -Eq '"remove\.(browser|dictation|gaming|service|windows|preinstalls)(\.|"|\})' \
  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc || \
  grep -Eq '"(update\.channel|trigger\.capture\.screenrecord\.)' \
  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc; then
  fail "Arch-only menu routes remain"
fi
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
  /usr/bin/omarchy-refresh-applications /usr/bin/omarchy-default-browser-select \
  /usr/bin/omarchy-menu-monitors
echo "Omarchy Quattro image validated."
