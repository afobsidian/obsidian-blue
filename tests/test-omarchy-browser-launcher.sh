#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

mkdir -p "$root/bin" "$root/applications"
cat >"$root/bin/omarchy-launch-browser" <<'EOF'
#!/bin/bash
default_browser=$(env -u BROWSER xdg-settings get default-web-browser)
if [[ -z $default_browser ]]; then
  default_browser=$(xdg-mime query default x-scheme-handler/https)
fi
browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' {~/.local,~/.nix-profile,/usr}/share/applications/$default_browser 2>/dev/null | head -1)

if $browser_exec --help 2>/dev/null | grep -q MOZ_LOG; then
  private_flag="--private-window"
elif [[ $browser_exec =~ edge ]]; then
  private_flag="--inprivate"
else
  private_flag="--incognito"
fi

systemd-run --user --quiet --collect --unit="omarchy-browser-$(date +%s%N)" \
  --property=StandardOutput=null --property=StandardError=null \
  uwsm-app -- "$browser_exec" "${@/--private/$private_flag}"

url=""
for argument in "$@"; do
  if [[ $argument != "--private" ]]; then
    url=$argument
    break
  fi
done

if [[ -n $url && -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  omarchy-hyprland-focus-app "^$(basename "$browser_exec" -stable).*$" || true
fi
EOF
(cd "$root" && git apply --recount <"$repo/files/patches/omarchy-browser-launcher.patch")
grep -Fq 'browser="chromium-browser.desktop"' "$repo/files/scripts/install-omarchy-quattro.sh"

mock="$root/mock"
mkdir -p "$mock"
cat >"$mock/xdg-settings" <<'EOF'
#!/bin/bash
[[ $1 == get ]] && printf '%s\n' "${BROWSER_ID:-}"
EOF
cat >"$mock/xdg-mime" <<'EOF'
#!/bin/bash
printf '%s\n' "${MIME_BROWSER_ID:-}"
EOF
cat >"$mock/systemd-run" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" >"$LAUNCH_LOG"
EOF
chmod +x "$mock"/*

for desktop_id in native.desktop app.zen_browser.zen.desktop; do
  cat >"$root/applications/$desktop_id" <<EOF
[Desktop Entry]
Exec=/usr/bin/browser %u

[Desktop Action new-private-window]
Exec=/usr/bin/browser --private-window %u
EOF
done

for desktop_id in native.desktop app.zen_browser.zen.desktop; do
  launch_log="$root/$desktop_id.log"
  PATH="$mock:$PATH" XDG_DATA_HOME="$root" XDG_DATA_DIRS= \
    BROWSER_ID="$desktop_id" LAUNCH_LOG="$launch_log" \
    bash "$root/bin/omarchy-launch-browser" https://example.test
  grep -Fqx gtk-launch "$launch_log"
  grep -Fqx "${desktop_id%.desktop}" "$launch_log"
  grep -Fqx https://example.test "$launch_log"
  PATH="$mock:$PATH" XDG_DATA_HOME="$root" XDG_DATA_DIRS= \
    BROWSER_ID="$desktop_id" LAUNCH_LOG="$launch_log" \
    bash "$root/bin/omarchy-launch-browser" --private https://example.test
  grep -Fqx /usr/bin/browser "$launch_log"
  grep -Fqx -- --private-window "$launch_log"
  grep -Fqx https://example.test "$launch_log"
done

launch_log="$root/fallback.log"
PATH="$mock:$PATH" XDG_DATA_HOME="$root" XDG_DATA_DIRS= \
  MIME_BROWSER_ID=native.desktop LAUNCH_LOG="$launch_log" \
  bash "$root/bin/omarchy-launch-browser" https://example.test
grep -Fqx native "$launch_log"
