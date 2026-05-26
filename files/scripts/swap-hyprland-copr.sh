#!/usr/bin/env bash

set -euo pipefail

# Disable older Hyprland COPRs shipped by the base image so the recipe can
# prefer the newer lionheartp/Hyprland packages.
OLD_HYPRLAND_REPOS=(
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo"
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:craftidore:wayblueorg-hyprland.repo"
)

for repo_file in "${OLD_HYPRLAND_REPOS[@]}"; do
    if [[ ! -f "${repo_file}" ]]; then
        echo "$(basename "${repo_file}") not found, skipping."
        continue
    fi

    if grep -q '^enabled=1' "${repo_file}"; then
        sed -i 's/^enabled=1$/enabled=0/' "${repo_file}"
        echo "Disabled $(basename "${repo_file}")."
    else
        echo "$(basename "${repo_file}") already disabled."
    fi
done
