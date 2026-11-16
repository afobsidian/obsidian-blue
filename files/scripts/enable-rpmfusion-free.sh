#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(mktemp -d)"
trap 'rm -rf "$repo_dir"' EXIT
cat >"$repo_dir/rpmfusion-bootstrap.repo" <<EOF
[rpmfusion-bootstrap]
name=RPM Fusion Free Rawhide bootstrap
baseurl=https://repo.fedora.md/mirrors/rpmfusion/free/fedora/development/rawhide/Everything/\$basearch/os/
        https://mirrors.lug.mtu.edu/rpmfusion/free/fedora/development/rawhide/Everything/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file://$script_dir/rpmfusion-free-2020.gpg
EOF
dnf -y --setopt="reposdir=$repo_dir" install rpmfusion-free-release
