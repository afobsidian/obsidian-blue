#!/usr/bin/env bash

set -euo pipefail

for cache_dir in /var/cache/libdnf5/rpmfusion-free* /var/cache/libdnf5/rpmfusion-nonfree*; do
    if [[ -e "${cache_dir}" ]]; then
        rm -rf "${cache_dir}"
    fi
done