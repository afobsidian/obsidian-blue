#!/usr/bin/env bash
set -euo pipefail

rpm -q --whatprovides 'liboapv.so.3()(64bit)' >/dev/null 2>&1 && exit 0

# shortcut: seed ABI 3 until RPM Fusion rebuilds FFmpeg for Rawhide's ABI 11.
package="$(mktemp --suffix=.rpm)"
trap 'rm -f "$package"' EXIT
curl -fsSL --retry 3 --connect-timeout 15 --max-time 120 \
  https://kojipkgs.fedoraproject.org/packages/openapv/0.3.0.0/1.fc46/data/signed/91211fce/x86_64/openapv-libs-0.3.0.0-1.fc46.x86_64.rpm \
  -o "$package"
printf '0f9544d3bf5d7ac39477e67b98e06aff74c215d292254fc8ca1c8915fc0ab553  %s\n' "$package" | sha256sum --check --status
dnf -y --setopt=localpkg_gpgcheck=True install "$package"
