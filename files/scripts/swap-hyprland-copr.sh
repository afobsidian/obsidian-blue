#!/usr/bin/env bash

set -euo pipefail

# Wayblue currently enables craftidore/wayblueorg-hyprland; older base images
# enabled solopasha/hyprland. Disable either inherited source before the DNF
# module temporarily adds lionheartp/Hyprland. This avoids letting package EVR
# ordering choose a source behind the recipe's back.
inherited_repos=(
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:craftidore:wayblueorg-hyprland.repo"
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo"
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:sdegler:hyprland.repo"
)

for repo_file in "${inherited_repos[@]}"; do
    if [[ -f "${repo_file}" ]]; then
        sed -i -E 's/^enabled[[:space:]]*=.*/enabled=0/' "${repo_file}"
        echo "Disabled inherited Hyprland repository: ${repo_file}"
    fi
done
