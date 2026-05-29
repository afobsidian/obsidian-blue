#!/usr/bin/env bash

set -euo pipefail

# Disable the solopasha/hyprland COPR shipped in the wayblue base image.
# Prefer lionheartp/Hyprland COPR.
SOLOPASHA_REPO="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo"
LION_REPO="/etc/yum.repos.d/lionheartp-hyprland.repo"

if [[ -f "${SOLOPASHA_REPO}" ]]; then
    sed -i 's/^enabled=1/enabled=0/' "${SOLOPASHA_REPO}"
    echo "Disabled solopasha/hyprland COPR."
else
    echo "solopasha/hyprland COPR repo file not found, skipping."
fi

# Ensure lionheartp repo is enabled if present so it's the preferred source.
if [[ -f "${LION_REPO}" ]]; then
    sed -i 's/^enabled=.*/enabled=1/' "${LION_REPO}" || true
    echo "Ensured lionheartp/Hyprland COPR is enabled."
else
    echo "lionheartp/Hyprland COPR repo file not found; proceeding without a Hyprland COPR."
fi
