#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/omarchy-version.env"

if rpm -q libcurl-minimal >/dev/null 2>&1; then
  dnf -y swap libcurl-minimal libcurl
fi

archive="$(mktemp)"
font_archive="$(mktemp)"
source_dir="$(mktemp -d)"
trap 'rm -f "$archive" "$font_archive"; rm -rf "$source_dir"' EXIT

curl -fsSL "https://codeload.github.com/basecamp/omarchy/tar.gz/$OMARCHY_COMMIT" -o "$archive"
echo "$OMARCHY_SHA256  $archive" | sha256sum --check --status
tar -xzf "$archive" --strip-components=1 -C "$source_dir"
(cd "$source_dir" && git apply --recount <"$script_dir/../patches/omarchy-browser-launcher.patch")

curl -fsSL \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS_VERSION/JetBrainsMono.tar.xz" \
  -o "$font_archive"
echo "$JETBRAINS_MONO_NERD_SHA256  $font_archive" | sha256sum --check --status
install -d /usr/share/fonts/jetbrains-mono-nerd
tar -xJf "$font_archive" -C /usr/share/fonts/jetbrains-mono-nerd \
  --wildcards 'JetBrainsMonoNerdFont-*.ttf'

install -d /usr/share/omarchy /usr/bin /usr/share/applications /usr/share/wayland-sessions
cp -a "$source_dir"/{applications,config,default,install,migrations,shell,themes} /usr/share/omarchy/
install -m 0644 "$source_dir"/{icon.png,icon.txt,logo.svg,logo.txt,version} /usr/share/omarchy/

menu=/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc
perl -0pi -e '
  s{^[ ]{2}"(?:
    trigger\.capture\.screenrecord\.(?:stop|no-audio|desktop-audio|microphone|webcam)|
    trigger\.share\.(?:clipboard|file|folder|receive)|
    style\.unlock|
    setup\.default\.browser\..*|
    setup\.security\.(?:fingerprint|fido2)|
    install\.aur|
    install\.style\.font(?:\..*)?|
    install\.(?:service|editor|terminal|browser|ai|gaming)(?:\..*)?|
    install\.(?:windows|preinstalls)|
    install\.development\.(?:php(?:\..*)?|clojure)|
    remove\.(?:browser|dictation|gaming|service|windows|preinstalls)(?:\..*)?|
    remove\.security\.(?:fingerprint|fido2)|
    remove\.development\.(?:php(?:\..*)?|clojure)|
    update\.channel(?:\..*)?|
    update\.config\.plymouth
  )":.*\n}{}mgx;
  s{^[ ]{2}"learn\.arch":.*\n}{  "learn.fedora": {"icon":"󰣇","label":"Fedora","action":"omarchy-launch-webapp '\''https://docs.fedoraproject.org/'\''"},\n}mg;
  s{^[ ]{2}"trigger\.capture\.screenrecord":.*\n}{  "trigger.capture.screenrecord": {"icon":"","label":"Open OBS Studio","when":"flatpak info com.obsproject.Studio","action":"uwsm-app -- flatpak run com.obsproject.Studio"},\n}mg;
  s{^[ ]{2}"trigger\.share":.*\n}{  "trigger.share": {"icon":"","label":"Open LocalSend","aliases":["share"],"when":"flatpak info org.localsend.localsend_app","action":"uwsm-app -- flatpak run org.localsend.localsend_app"},\n}mg;
  s{^[ ]{2}"setup\.monitors":.*\n}{  "setup.monitors": {"icon":"󰍹","label":"Monitors","action":"omarchy-menu-monitors"},\n}mg;
  s{^[ ]{2}"setup\.default\.browser":.*\n}{  "setup.default.browser": {"icon":"","label":"Browser","title":"Default Browser","action":"omarchy-default-browser-select"},\n}mg;
  s{^[ ]{2}"setup\.default\.editor\.zed":.*\n}{  "setup.default.editor.zed": {"icon":"","label":"Zed","when":"omarchy-cmd-present zed","checked":"[[ \\"\$(omarchy-default-editor)\\" == \\"zed\\" ]]","action":"omarchy-default-editor zed"},\n}mg;
  s{^[ ]{2}"install\.package":.*\n}{  "install.package": {"icon":"󰏗","label":"Flatpak","action":"xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-install"},\n}mg;
  s{^[ ]{2}"remove\.package":.*\n}{  "remove.package": {"icon":"󰏗","label":"Flatpak","action":"xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-remove"},\n}mg;
' "$menu"
grep -Fq '"learn.fedora"' "$menu"
grep -Fq '"setup.default.browser"' "$menu"
grep -Fq '"install.package": {"icon":"󰏗","label":"Flatpak"' "$menu"
if grep -Eq '"install\.(aur|style\.font|service|editor|terminal|browser|ai|gaming|windows|preinstalls)(\.|"|\})' "$menu" || \
  grep -Eq '"remove\.(browser|dictation|gaming|service|windows|preinstalls)(\.|"|\})' "$menu" || \
  grep -Eq '"(update\.channel|trigger\.capture\.screenrecord\.)' "$menu"; then
  echo 'Unsupported Arch menu routes remain.' >&2
  exit 1
fi
sed -i '/require("hypr.monitors")/a dofile("/usr/share/obsidian-blue/load-user-monitors.lua")' \
  /usr/share/omarchy/config/hypr/hyprland.lua

for executable in "$source_dir"/bin/*; do
  [[ -f "$executable" ]] || continue
  install -m 0755 "$executable" "/usr/bin/$(basename "$executable")"
done
sed -i 's/browser="chromium\.desktop"/browser="chromium-browser.desktop"/' \
  /usr/bin/omarchy-launch-webapp
grep -Fq 'browser="chromium-browser.desktop"' /usr/bin/omarchy-launch-webapp

sed -i \
  's|local monitor_lua="$HOME/.config/hypr/monitors.lua"|local monitor_lua="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hypr/monitors.lua"|' \
  /usr/bin/omarchy-hyprland-monitor-scaling
grep -Fq '/omarchy/hypr/monitors.lua' /usr/bin/omarchy-hyprland-monitor-scaling

sed -i '/^LOGO_FILE=/a [[ -f "$LOGO_FILE" ]] || LOGO_FILE="$OMARCHY_PATH/icon.txt"' \
  /usr/bin/omarchy-launch-about
sed -i \
  -e '/^while true; do$/i screensaver_file="$HOME/.config/omarchy/branding/screensaver.txt"\n[[ -f "$screensaver_file" ]] || screensaver_file="$OMARCHY_PATH/logo.txt"\n' \
  -e 's|ttfx -i ~/.config/omarchy/branding/screensaver.txt|ttfx -i "$screensaver_file"|' \
  /usr/bin/omarchy-screensaver
for command in /usr/bin/omarchy-branding-about /usr/bin/omarchy-branding-screensaver; do
  sed -i '/^set -euo pipefail$/a mkdir -p "$HOME/.config/omarchy/branding"' "$command"
done

install -d /usr/share/omarchy/bin
for executable in /usr/bin/omarchy*; do
  [[ -f "$executable" ]] || continue
  ln -sfn "$executable" "/usr/share/omarchy/bin/$(basename "$executable")"
done

for source in "$source_dir"/config/*; do
  rm -rf "/etc/skel/.config/$(basename "$source")"
done
rm -rf /etc/skel/.config/omadora /etc/skel/.config/waybar /etc/skel/.local/share/omadora

for desktop in "$source_dir"/applications/*.desktop; do
  install -m 0644 "$desktop" "/usr/share/applications/$(basename "$desktop")"
  rm -f "/etc/skel/.local/share/applications/$(basename "$desktop")"
done
if compgen -G "$source_dir/applications/hidden/*.desktop" >/dev/null; then
  for desktop in "$source_dir"/applications/hidden/*.desktop; do
    install -m 0644 "$desktop" "/usr/share/applications/$(basename "$desktop")"
    rm -f "/etc/skel/.local/share/applications/$(basename "$desktop")"
  done
fi
install -m 0644 "$source_dir/default/alacritty/Alacritty.desktop" \
  /usr/share/applications/Alacritty.desktop
for icon in "$source_dir"/applications/icons/*; do
  [[ -f "$icon" ]] || continue
  name="$(basename "${icon%.*}" | tr '[:upper:]' '[:lower:]' | sed 's/[^[:alnum:]]\+/-/g')"
  if [[ "$icon" == *.svg ]]; then
    install -Dm644 "$icon" "/usr/share/icons/hicolor/scalable/apps/$name.svg"
  else
    install -d /usr/share/icons/hicolor/256x256/apps
    magick "$icon" -thumbnail 256x256 -background transparent -gravity center -extent 256x256 \
      "PNG32:/usr/share/icons/hicolor/256x256/apps/$name.png"
  fi
done
install -Dm644 "$source_dir/default/uwsm/env.d/10-omarchy" /usr/share/uwsm/env.d/10-omarchy
install -Dm644 "$source_dir/default/bash/env-bootstrap" /etc/profile.d/omarchy.sh
install -Dm644 "$source_dir/default/environment.d/10-omarchy-fcitx.conf" \
  /usr/lib/environment.d/10-omarchy-fcitx.conf
install -Dm644 "$source_dir/default/fontconfig/conf.avail/50-omarchy.conf" \
  /usr/share/fontconfig/conf.avail/50-omarchy.conf
install -d /etc/fonts/conf.d
ln -sfn /usr/share/fontconfig/conf.avail/50-omarchy.conf /etc/fonts/conf.d/50-omarchy.conf
install -Dm644 "$source_dir/default/xdg-terminal-exec/hyprland-xdg-terminals.list" \
  /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list
install -Dm644 "$source_dir/default/applications/mimeapps.list" /usr/share/applications/mimeapps.list

for unit in "$source_dir"/default/systemd/user/*.service; do
  install -Dm644 "$unit" "/usr/lib/systemd/user/$(basename "$unit")"
done
install -Dm644 "$source_dir/default/systemd/user/app.slice.d/10-oomd.conf" \
  /usr/lib/systemd/user/app.slice.d/10-oomd.conf
install -Dm644 "$source_dir/default/systemd/zram-generator.conf.d/90-omarchy.conf" \
  /usr/lib/systemd/zram-generator.conf.d/90-omarchy.conf

cp -a "$source_dir/default/sddm/omarchy" /usr/share/sddm/themes/
install -Dm644 "$source_dir/default/sddm/hyprland.lua" /usr/share/sddm/hyprland.lua
install -Dm644 "$source_dir/etc/sddm.conf.d/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
install -Dm644 "$source_dir/etc/sddm.conf.d/10-wayland.conf" /etc/sddm.conf.d/10-wayland.conf
install -Dm644 "$source_dir/default/wayland-sessions/omarchy.desktop" \
  /usr/share/wayland-sessions/omarchy.desktop
rm -f /etc/sddm.conf.d/theme.conf
for session in omarchy.desktop hyprland.desktop hyprland-uwsm.desktop; do
  [[ -f "/usr/share/wayland-sessions/$session" ]] || continue
  sed -i 's|^Exec=.*|Exec=/usr/bin/obsidian-blue-quattro-session|' \
    "/usr/share/wayland-sessions/$session"
done

install -d /usr/share/plymouth/themes/omarchy
cp -a "$source_dir/default/plymouth/." /usr/share/plymouth/themes/omarchy/
install -Dm644 "$source_dir/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/omarchy.ttf
fc-cache -f
install -Dm755 "$source_dir/default/systemd/system-sleep/unmount-fuse" \
  /usr/lib/systemd/system-sleep/unmount-fuse
install -Dm644 "$source_dir/etc/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc
install -Dm644 "$source_dir/icon.png" /usr/share/pixmaps/omarchy.png
install -Dm644 "$source_dir/icon.png" /usr/share/icons/hicolor/256x256/apps/omarchy.png

install -Dm644 "$source_dir/default/hypr/toggles/flags.lua" \
  /etc/skel/.local/state/omarchy/toggles/hypr/flags.lua
install -Dm644 "$source_dir/default/nautilus-python/extensions/localsend.py" \
  /usr/share/nautilus-python/extensions/localsend.py
install -Dm644 "$source_dir/default/nautilus-python/extensions/transcode.py" \
  /usr/share/nautilus-python/extensions/transcode.py

HOME=/etc/skel XDG_RUNTIME_DIR=/tmp OMARCHY_PATH=/usr/share/omarchy \
  OMARCHY_THEME_HEADLESS=1 PATH=/usr/share/omarchy/bin:/usr/bin:/bin \
  omarchy-theme-set "Tokyo Night"

for source in "$source_dir"/config/*; do
  rm -rf "/etc/skel/.config/$(basename "$source")"
done
rm -rf /etc/skel/.config/omadora /etc/skel/.config/waybar

install -d /etc/skel/.local/state/omarchy/migrations /etc/skel/.local/state/obsidian-blue
for migration in "$source_dir"/migrations/*.sh; do
  touch "/etc/skel/.local/state/omarchy/migrations/$(basename "$migration")"
done
touch /etc/skel/.local/state/obsidian-blue/quattro-4.0.0-image-config-v3

install -Dm644 "$script_dir/omarchy-version.env" /usr/share/obsidian-blue/omarchy-version.env
install -Dm755 /usr/bin/omarchy-hyprland-monitor-scaling \
  /usr/libexec/obsidian-blue/omarchy-hyprland-monitor-scaling

for adapter in /usr/libexec/obsidian-blue/omarchy-adapters/*; do
  install -m 0755 "$adapter" "/usr/bin/$(basename "$adapter")"
done
