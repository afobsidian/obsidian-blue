#!/usr/bin/env bash
# Write a build timestamp into the omadora skel directory so the onboarding
# service can detect when the image has been rebased/updated.
set -euo pipefail

target_dir="/etc/skel/.local/share/omadora"
target_file="${target_dir}/.obsidian-blue-build"
build_version="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "${target_dir}"
printf '%s\n' "${build_version}" > "${target_file}"
echo "Build version written: $(cat "${target_file}")"
