#!/usr/bin/env bash
set -euo pipefail

archive="$(mktemp)"
source_dir="$(mktemp -d)"
trap 'rm -f "$archive"; rm -rf "$source_dir"' EXIT
curl -fsSL 'https://codeload.github.com/omacom/omarchy-hyprland-titlebars/tar.gz/b351b14bbed4b04ed55e6380e03784edcee68399' -o "$archive"
echo 'b0f9d943da34cdeec56dac70661d86e94f63eaf2ef3c7f327b13b6fb1f9cc4fd  '"$archive" | sha256sum --check --status
tar -xzf "$archive" --strip-components=1 -C "$source_dir"
cmake -S "$source_dir" -B "$source_dir/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$source_dir/build" --parallel 2
cmake --install "$source_dir/build"
