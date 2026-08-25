#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

menu="$root/omarchy-menu.jsonc"
cat >"$menu" <<'EOF'
{
  "learn.arch": {"action":"arch"},
  "trigger.capture.screenrecord": {"action":"record"},
  "trigger.capture.screenrecord.stop": {"action":"stop"},
  "trigger.share": {"action":"share"},
  "trigger.share.file": {"action":"share-file"},
  "style.unlock": {"action":"unlock"},
  "setup.monitors": {"action":"monitor"},
  "setup.default.browser": {"action":"browser"},
  "setup.default.browser.zen": {"action":"zen"},
  "setup.default.editor.zed": {"action":"zed"},
  "setup.security.fingerprint": {"action":"fingerprint"},
  "setup.security.fido2": {"action":"fido2"},
  "setup.direct-boot": {"action":"boot"},
  "setup.reset": {"action":"reset"},
  "install.package": {"action":"package"},
  "install.aur": {"action":"aur"},
  "install.browser": {"action":"browser"},
  "install.browser.zen": {"action":"zen"},
  "install.style.font": {"action":"font"},
  "install.development.go": {"action":"go"},
  "install.development.php": {"action":"php"},
  "install.development.clojure": {"action":"clojure"},
  "remove.package": {"action":"package"},
  "remove.browser": {"action":"browser"},
  "remove.security": {"action":"security"},
  "remove.security.sshd": {"action":"sshd"},
  "remove.development.go": {"action":"go"},
  "remove.development.php": {"action":"php"},
  "update.omarchy": {"action":"update"},
  "update.channel": {"action":"channel"},
  "update.channel.stable": {"action":"stable"},
  "update.config.plymouth": {"action":"plymouth"},
  "update.firmware": {"action":"firmware"}
}
EOF

sed -n '30,66p' "$repo/files/scripts/install-omarchy-quattro.sh" |
  sed "s|menu=/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc|menu=$menu|" | bash

grep -Fq '"learn.fedora"' "$menu"
grep -Fq 'Open OBS Studio' "$menu"
grep -Fq 'Open LocalSend' "$menu"
grep -Fq 'omarchy-menu-monitors' "$menu"
grep -Fq 'omarchy-default-browser-select' "$menu"
grep -Fq 'omarchy-cmd-present zed' "$menu"
grep -Fq '"setup.direct-boot"' "$menu"
grep -Fq '"setup.reset"' "$menu"
grep -Fq '"update.firmware"' "$menu"
grep -Fq '"install.development.go"' "$menu"
grep -Fq '"remove.development.go"' "$menu"
grep -Fq '"remove.security.sshd"' "$menu"
if grep -Eq '"install\.(aur|style\.font|service|editor|terminal|browser|ai|gaming|windows|preinstalls)(\.|"|\})' "$menu" || \
  grep -Eq '"remove\.(browser|dictation|gaming|service|windows|preinstalls)(\.|"|\})' "$menu" || \
  grep -Eq '"(update\.channel|trigger\.capture\.screenrecord\.)' "$menu"; then
  exit 1
fi

home="$root/home"
mock="$root/mock"
mkdir -p "$home/.local/share/applications" "$mock"
cat >"$home/.local/share/applications/app.zen_browser.zen.desktop" <<'EOF'
[Desktop Entry]
Name=Zen Browser
MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;
EOF
cat >"$mock/omarchy-menu-select" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$SELECT_ARGS"
printf 'Zen Browser\tapp.zen_browser.zen.desktop\n'
EOF
cat >"$mock/xdg-settings" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$SETTINGS_ARGS"
EOF
cat >"$mock/xdg-mime" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$MIME_ARGS"
EOF
cat >"$mock/omarchy-notification-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$mock/omarchy-launch-config-editor" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >"$EDITOR_PATH"
EOF
chmod +x "$mock"/*

PATH="$mock:$PATH" HOME="$home" XDG_DATA_HOME="$home/.local/share" SELECT_ARGS="$root/select" \
  SETTINGS_ARGS="$root/settings" MIME_ARGS="$root/mime" \
  "$repo/files/usr/libexec/obsidian-blue/omarchy-adapters/omarchy-default-browser-select"
grep -Fq 'Zen Browser' "$root/select"
grep -Fqx $'Zen Browser\tapp.zen_browser.zen.desktop' "$root/select"
grep -Fqx 'set' "$root/settings"
grep -Fqx 'default-web-browser' "$root/settings"
grep -Fqx 'app.zen_browser.zen.desktop' "$root/settings"
grep -Fqx 'x-scheme-handler/https' "$root/mime"

config_root="$root/config"
mkdir -p "$config_root/hypr"
printf 'monitor config\n' >"$config_root/hypr/monitors.lua"
PATH="$mock:$PATH" HOME="$home" XDG_CONFIG_HOME="$home/.config" \
  OMARCHY_CONFIG_ROOT="$config_root" EDITOR_PATH="$root/editor" \
  "$repo/files/usr/libexec/obsidian-blue/omarchy-adapters/omarchy-menu-monitors"
test "$(cat "$home/.config/omarchy/hypr/monitors.lua")" = 'monitor config'
test "$(cat "$root/editor")" = "$home/.config/omarchy/hypr/monitors.lua"
