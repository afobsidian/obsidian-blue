#!/usr/bin/env bash
set -euo pipefail
RUSTLE_VERSION=0.0.4
[[ "$(uname -m)" == x86_64 ]]
dnf -y install pipewire-utils pipewire-pulseaudio pulseaudio-utils wireplumber python3 curl dbus-tools dbus-daemon

name="rustle-$RUSTLE_VERSION-x86_64-unknown-linux-gnu.tar.gz"
url="https://github.com/afobsidian/rustle/releases/download/v$RUSTLE_VERSION/$name"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
curl --fail --location --retry 2 --connect-timeout 15 --max-time 300 "$url" -o "$staging/$name"
curl --fail --location --retry 2 --connect-timeout 15 --max-time 60 "$url.sha256" -o "$staging/checksum"
checksum="$(awk 'NR == 1 { print $1 }' "$staging/checksum")"
[[ "$checksum" =~ ^[a-f0-9]{64}$ ]]
printf '%s  %s\n' "$checksum" "$staging/$name" | sha256sum --check --status
python3 - "$staging/$name" <<'PY'
import sys, tarfile
with tarfile.open(sys.argv[1]) as archive:
    archive.extractall('/', filter='data')
PY
