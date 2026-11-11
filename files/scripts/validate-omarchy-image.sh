#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "Omarchy image validation failed: $*" >&2
  exit 1
}

for command in Hyprland flatpak hyprlock quickshell uwsm omarchy omarchy-migrate herdr podman docker gh nvim fd rg nmtui xkbcli \
  tailscale perf nc curl rsync; do
  command -v "$command" >/dev/null || fail "missing command: $command"
done

perl -MJSON::PP -e 1 || fail "missing Perl JSON::PP module"
rpm -q disktree-bin gliff omasnap owe owe-lockfeed xsetroot \
  fcitx5-chewing fcitx5-chinese-addons fcitx5-hangul fcitx5-mozc \
  gcc gcc-c++ make qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel \
  qt6-qtsvg-devel qt6-qtwayland-devel ffmpeg-devel \
  libva-intel-media-driver libvpl intel-vpl-gpu-rt >/dev/null || \
  fail "Omarchy 4.5 packages are absent"
ffmpeg_encoders="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
grep -q libx264 <<<"$ffmpeg_encoders" || fail "FFmpeg H.264 encoding is absent"
curl_protocols="$(curl --version | sed -n 's/^Protocols: //p')"
grep -Eq '(^| )imap( |$)' <<<"$curl_protocols" || fail "curl IMAP support is absent"
grep -Eq '(^| )imaps( |$)' <<<"$curl_protocols" || fail "curl IMAPS support is absent"

for path in \
  /usr/local/sbin \
  /etc/tmpfiles.d/root.conf \
  /etc/xkb/rules/evdev \
  /etc/xkb/symbols/omarchy \
  /usr/share/omarchy/version \
  /usr/share/omarchy/shell/shell.qml \
  /usr/share/omarchy/config/hypr/hyprland.lua \
  /usr/share/omarchy/themes/tokyo-night/colors.toml \
  /usr/share/omarchy-nvim/config/lua/config/lazy.lua \
  /etc/skel/.config/nvim/lua/plugins/theme.lua \
  /usr/bin/omarchy-nvim-setup \
  /usr/bin/omarchy-default-browser-select \
  /usr/bin/omarchy-migrate \
  /usr/bin/omarchy-menu-monitors \
  /etc/profile.d/omarchy.sh \
  /etc/profile.d/99-omarchy-bash.sh \
  /etc/pam.d/omarchy-lock-password \
  /etc/systemd/logind.conf.d/20-inhibit-delay.conf \
  /etc/skel/.local/state/obsidian-blue/quattro-4.5.0-image-config-v4 \
  /etc/skel/.local/state/omarchy/migrations/1780000000-obsidian-preinstalls.sh \
  /usr/share/wayland-sessions/omarchy.desktop \
  /usr/share/applications/Alacritty.desktop \
  /usr/libexec/obsidian-blue/omarchy-hyprland-monitor-scaling \
  /usr/share/obsidian-blue/load-user-monitors.lua \
  /usr/lib/omarchy-hyprland-titlebars/titlebars.so \
  /etc/skel/.config/omarchy/hooks/theme-set.d/10-owe-sync \
  /usr/share/nautilus-python/extensions/localsend.py; do
  [[ -e "$path" ]] || fail "missing path: $path"
done

xkb_map="$(xkbcli compile-keymap --layout us --options omarchy:shift_caps_compose 2>&1)" || \
  fail "Omarchy keyboard option cannot be compiled"
if grep -Fq 'Unrecognized RMLVO option "omarchy:shift_caps_compose"' <<<"$xkb_map"; then
  fail "Omarchy keyboard option is not registered"
fi

grep -Fqx 'auth include login' /etc/pam.d/omarchy-lock-password || \
  fail "Fedora lock PAM stack is absent"
grep -Fqx 'InhibitDelayMaxSec=15' /etc/systemd/logind.conf.d/20-inhibit-delay.conf || \
  fail "logind suspend inhibitor window is not 15 seconds"
lock_service=/usr/share/omarchy/shell/plugins/lock/Service.qml
grep -Fq 'function currentlyLocked()' "$lock_service" || fail "upstream lock state fix is absent"
grep -Fq 'if (!root.currentlyLocked() && !root.beginLock()) return "failed"' "$lock_service" || \
  fail "lock request does not check the current session state"
! grep -Fq 'if (!strandedLock || locked || !passwordPamConfigured)' "$lock_service" || \
  fail "stale stranded-lock recovery reference remains"
grep -Fqx 'NAME="obsidian-blue"' /usr/lib/os-release || fail "image name is not branded"
grep -Fqx 'DEFAULT_HOSTNAME="obsidian-blue"' /usr/lib/os-release || \
  fail "default hostname is not branded"
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

for path in /etc/skel/.config/hypr /etc/skel/.config/waybar \
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
grep -Fq 'source /usr/share/obsidian-blue/omarchy-version.env' /usr/bin/obsidian-blue-quattro-session || \
  fail "session does not use the image migration version"
grep -Fq 'start-hyprland -- --config "$config"' /usr/bin/obsidian-blue-quattro-session || \
  fail "session launcher bypasses start-hyprland"
grep -Fqx 'export HYPRLAND_NO_RT=1' /usr/share/uwsm/env.d/20-obsidian-blue-hyprland || \
  fail "Hyprland real-time scheduling workaround is absent"
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
# Hyprland 0.57's verifier crashes if root can create /.socket2.sock.
chown nobody:nobody "$home" "$runtime"
# The verifier tears down its event loop before startup cursor timers; skip that
# timer only in this temporary wrapper, while still parsing the real config.
printf '%s\n' 'omarchy_startup_cursor_pending = false' \
  'dofile("/usr/share/omarchy/config/hypr/hyprland.lua")' >"$home/verify.lua"
chown nobody:nobody "$home/verify.lua"
luac -p /usr/share/omarchy/default/hypr/startup-cursor.lua
runuser -u nobody -- env HOME="$home" OMARCHY_PATH=/usr/share/omarchy \
  XDG_RUNTIME_DIR="$runtime" \
  LUA_PATH='/usr/share/omarchy/config/?.lua;;' \
  Hyprland --verify-config \
    --config "$home/verify.lua"

bash -n /usr/bin/obsidian-blue-quattro-session /usr/libexec/obsidian-blue/quattro-migrate \
  /usr/bin/omarchy-migrate \
  /usr/bin/omarchy-refresh-applications /usr/bin/omarchy-default-browser-select \
  /usr/bin/omarchy-menu-monitors /usr/bin/obsidian-blue-setup

[[ -x /usr/bin/obsidian-blue-setup ]] || fail "first-login setup is absent"
grep -Fqx 'ExecStartPost=/usr/bin/obsidian-blue-setup --first-login' \
  /usr/lib/systemd/user/omarchy-migrate-notify.service.d/20-obsidian-blue-setup.conf || fail "first-login setup hook is absent"

[[ -f /etc/skel/.local/state/omarchy/preinstalls-removed ]] || fail "preinstall opt-out is absent"
if grep -El '^Exec=(omarchy-launch-webapp|omarchy-webapp-handler|xdg-terminal-exec --app-id=TUI\.)' /usr/share/applications/*.desktop; then
  fail "preinstalled web apps or TUIs remain"
fi
for package in hype monologue signed; do
  if rpm -q "$package" >/dev/null 2>&1; then
    fail "removed preinstall remains: $package"
  fi
done
grep -Fqx '[tools]' /etc/mise/conf.d/omarchy-tools.toml || fail "mise compatibility file is absent"
if grep -Eq '^[[:alnum:]"].*=' /etc/mise/conf.d/omarchy-tools.toml; then
  fail "optional mise tools remain"
fi
bash -euo pipefail /usr/share/omarchy/migrations/1792504295.sh
qt_version="$(rpm -q --qf '%{VERSION}\n' qt6-qtbase)"
[[ "$(printf '6.12.0\n%s\n' "$qt_version" | sort -V | head -1)" == 6.12.0 ]] || fail "Qt 6.12 or newer is required"
command -v bootc >/dev/null || fail "bootc update support is absent"
quickshell --version >/dev/null || fail "Quickshell cannot load against the installed Qt"
echo "Omarchy Quattro image validated."
