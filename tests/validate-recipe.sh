#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
recipe="$repo/recipes/recipe.yml"

grep -Fqx 'base-image: quay.io/fedora/fedora-bootc' "$recipe"
grep -Fqx 'image-version: rawhide' "$recipe"
grep -Fqx 'name: obsidian-blue-rawhide' "$recipe"
grep -Fq 'install-omarchy-apps.sh' "$recipe"
grep -Fq 'install-omarchy-quattro.sh' "$recipe"
grep -Fq 'podman-docker' "$recipe"
grep -Fq 'NetworkManager-tui' "$recipe"
grep -Fq 'tailscale' "$recipe"
grep -Fq 'libxkbcommon-utils' "$recipe"
grep -Fq 'perl-JSON-PP' "$recipe"
grep -Fq '        - curl' "$recipe"
grep -Fq '        - libcurl.x86_64' "$recipe"
grep -Fq '        - cups-pk-helper' "$recipe"
grep -Fq '        - qt6-qtimageformats' "$recipe"
grep -Fq '        - curl-minimal' "$recipe"
curl_protocols="$(curl --version | sed -n 's/^Protocols: //p')"
grep -Eq '(^| )imap( |$)' <<<"$curl_protocols"
grep -Eq '(^| )imaps( |$)' <<<"$curl_protocols"
grep -Fq 'type: brew' "$recipe"
grep -Fq 'brew-analytics: false' "$recipe"
grep -Fq 'type: os-release' "$recipe"
grep -Fq 'DEFAULT_HOSTNAME: obsidian-blue' "$recipe"
grep -Fq 'scope: system' "$recipe"
if grep -Eq '^[[:space:]]*- (hype|monologue|signed|com.github.PintaProject.Pinta|com.moonlight_stream.Moonlight|md.obsidian.Obsidian|org.libreoffice.LibreOffice)$' "$recipe"; then
  echo "Removed preinstall remains in recipe" >&2
  exit 1
fi
if sed -n '/    install:/,/    remove:/p' "$recipe" | \
  grep -Ei '^[[:space:]]*-[[:space:]]*(omadora|monique|waybar-git|visual-studio-code|kubectl|helm)([[:space:]]|$)' >/dev/null; then
  echo "Unsupported package in recipe" >&2
  exit 1
fi
grep -Fq 'omarchy-migrate-notify.service' "$recipe"
grep -Fq '/usr/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
! grep -Fq '/usr/local/share/wayland-sessions/omarchy.desktop' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'quattro-$version-image-config-v4' \
  "$repo/files/usr/libexec/obsidian-blue/quattro-migrate"
grep -Fq 'omarchy-default-browser-select' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'omarchy-menu-monitors' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Open OBS Studio' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Open LocalSend' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'JETBRAINS_MONO_NERD_SHA256=' "$repo/files/scripts/omarchy-version.env"
test ! -e "$repo/.gitmodules"
grep -Fqx 'auth include login' "$repo/files/etc/pam.d/omarchy-lock-password"
grep -Fq 'omarchy-browser-launcher.patch' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'etc/systemd/logind.conf.d/20-inhibit-delay.conf' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Unadapted Fedora migration' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'omarchy-migrations' "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'dnf -y swap libcurl-minimal libcurl' \
  "$repo/files/scripts/install-omarchy-quattro.sh"
grep -Fq 'Private browser binding is absent' "$repo/files/scripts/validate-omarchy-image.sh"
grep -Fq 'install-omarchy-nvim.sh' "$recipe"
grep -Fq 'OMARCHY_NVIM_SHA256=' "$repo/files/scripts/omarchy-nvim-version.env"

find "$repo/files" "$repo/scripts" "$repo/tests" -type f -name '*.sh' -print0 | \
  xargs -0 -n1 bash -n
