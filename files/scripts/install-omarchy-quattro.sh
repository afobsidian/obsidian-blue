#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/omarchy-version.env"

archive="$(mktemp)"
source_dir="$(mktemp -d)"
trap 'rm -f "$archive"; rm -rf "$source_dir"' EXIT

curl -fsSL "https://codeload.github.com/basecamp/omarchy/tar.gz/$OMARCHY_COMMIT" -o "$archive"
echo "$OMARCHY_SHA256  $archive" | sha256sum --check --status
tar -xzf "$archive" --strip-components=1 -C "$source_dir"

install -d /usr/share/omarchy /usr/bin /etc/skel/.config /etc/skel/.local/share/applications
cp -a "$source_dir"/{applications,config,default,install,migrations,shell,themes} /usr/share/omarchy/
install -m 0644 "$source_dir"/{icon.png,icon.txt,logo.svg,logo.txt,version} /usr/share/omarchy/

for executable in "$source_dir"/bin/*; do
  [[ -f "$executable" ]] || continue
  install -m 0755 "$executable" "/usr/bin/$(basename "$executable")"
done

install -d /usr/share/omarchy/bin
for executable in /usr/bin/omarchy*; do
  [[ -f "$executable" ]] || continue
  ln -sfn "$executable" "/usr/share/omarchy/bin/$(basename "$executable")"
done

cp -a "$source_dir/config/." /etc/skel/.config/
cp -a "$source_dir/applications"/*.desktop /etc/skel/.local/share/applications/
if compgen -G "$source_dir/applications/hidden/*.desktop" >/dev/null; then
  cp -a "$source_dir/applications/hidden"/*.desktop /etc/skel/.local/share/applications/
fi
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
install -Dm644 "$source_dir/default/bashrc" /etc/skel/.bashrc
install -Dm644 "$source_dir/default/uwsm/env.d/10-omarchy" /usr/share/uwsm/env.d/10-omarchy
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
  /usr/local/share/wayland-sessions/omarchy.desktop
sed -i 's|^Exec=.*|Exec=/usr/bin/obsidian-blue-quattro-session|' \
  /usr/local/share/wayland-sessions/omarchy.desktop

install -d /usr/share/plymouth/themes/omarchy
cp -a "$source_dir/default/plymouth/." /usr/share/plymouth/themes/omarchy/
install -Dm644 "$source_dir/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/omarchy.ttf
install -Dm755 "$source_dir/default/systemd/system-sleep/unmount-fuse" \
  /usr/lib/systemd/system-sleep/unmount-fuse
install -Dm644 "$source_dir/etc/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc
install -Dm644 "$source_dir/icon.png" /usr/share/pixmaps/omarchy.png
install -Dm644 "$source_dir/icon.png" /usr/share/icons/hicolor/256x256/apps/omarchy.png

install -Dm644 "$source_dir/logo.txt" /etc/skel/.config/omarchy/branding/screensaver.txt
install -Dm644 "$source_dir/icon.txt" /etc/skel/.config/omarchy/branding/about.txt
install -Dm644 "$source_dir/default/hypr/toggles/flags.lua" \
  /etc/skel/.local/state/omarchy/toggles/hypr/flags.lua
install -Dm644 "$source_dir/default/nautilus-python/extensions/localsend.py" \
  /etc/skel/.local/share/nautilus-python/extensions/localsend.py
install -Dm644 "$source_dir/default/nautilus-python/extensions/transcode.py" \
  /etc/skel/.local/share/nautilus-python/extensions/transcode.py

HOME=/etc/skel XDG_RUNTIME_DIR=/tmp OMARCHY_PATH=/usr/share/omarchy \
  OMARCHY_THEME_HEADLESS=1 PATH=/usr/share/omarchy/bin:/usr/bin:/bin \
  omarchy-theme-set "Tokyo Night"

install -d /etc/skel/.local/state/omarchy/migrations /etc/skel/.local/state/obsidian-blue
for migration in "$source_dir"/migrations/*.sh; do
  touch "/etc/skel/.local/state/omarchy/migrations/$(basename "$migration")"
done
touch /etc/skel/.local/state/obsidian-blue/quattro-4.0.0

install -Dm644 "$script_dir/omarchy-version.env" /usr/share/obsidian-blue/omarchy-version.env

for adapter in /usr/libexec/obsidian-blue/omarchy-adapters/*; do
  install -m 0755 "$adapter" "/usr/bin/$(basename "$adapter")"
done
