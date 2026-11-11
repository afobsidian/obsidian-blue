#!/usr/bin/env bash
set -euo pipefail

release_rpm="$(mktemp --suffix=.rpm)"
trap 'rm -f "$release_rpm"' EXIT
curl -fsSL --retry 3 --connect-timeout 15 --max-time 120 \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm -o "$release_rpm" ||
  curl -fsSL --retry 3 --connect-timeout 15 --max-time 120 \
    https://repo.fedora.md/mirrors/rpmfusion/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm -o "$release_rpm"
printf '9365a2240104c56efb81feaca1fdd0e9b36c93bb6dc1001dea0967261faf867e  %s\n' "$release_rpm" | sha256sum --check --status
dnf -y install "$release_rpm"
