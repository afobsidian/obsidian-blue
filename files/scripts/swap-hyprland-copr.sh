#!/usr/bin/env bash

set -euo pipefail

# Disable the solopasha/hyprland COPR shipped in the wayblue base image.
# sdegler/hyprland is the actively-maintained fork and replaces it.
SOLOPASHA_REPO="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo"

if [[ -f "${SOLOPASHA_REPO}" ]]; then
    sed -i 's/^enabled=1/enabled=0/' "${SOLOPASHA_REPO}"
    echo "Disabled solopasha/hyprland COPR."
else
    echo "solopasha/hyprland COPR repo file not found, skipping."
fi
