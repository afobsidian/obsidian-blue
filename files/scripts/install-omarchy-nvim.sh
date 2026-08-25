#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/omarchy-nvim-version.env"

archive="$(mktemp)"
starter_archive="$(mktemp)"
source_dir="$(mktemp -d)"
starter_dir="$(mktemp -d)"
build_home="$(mktemp -d)"
trap 'rm -f "$archive" "$starter_archive"; rm -rf "$source_dir" "$starter_dir" "$build_home"' EXIT

curl -fsSL "https://codeload.github.com/omacom-io/omarchy-pkgs/tar.gz/$OMARCHY_NVIM_COMMIT" -o "$archive"
echo "$OMARCHY_NVIM_SHA256  $archive" | sha256sum --check --status
tar -xzf "$archive" --strip-components=1 -C "$source_dir"

curl -fsSL "https://github.com/LazyVim/starter/archive/refs/heads/main.tar.gz" -o "$starter_archive"
echo "$LAZYVIM_STARTER_SHA256  $starter_archive" | sha256sum --check --status
tar -xzf "$starter_archive" --strip-components=1 -C "$starter_dir"

export HOME="$build_home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

cp -a "$starter_dir" "$XDG_CONFIG_HOME/nvim"
rm -rf "$XDG_CONFIG_HOME/nvim/.git"
cp -a "$source_dir/pkgbuilds/omarchy-nvim/lua" "$XDG_CONFIG_HOME/nvim/"
cp -a "$source_dir/pkgbuilds/omarchy-nvim/plugin" "$XDG_CONFIG_HOME/nvim/"
cp "$source_dir/pkgbuilds/omarchy-nvim/lazyvim.json" "$XDG_CONFIG_HOME/nvim/"
nvim --headless "+Lazy! sync" "+qa!" || true

install -d /usr/share/omarchy-nvim/config /etc/skel/.config /etc/skel/.local/share
cp -a "$XDG_CONFIG_HOME/nvim/." /usr/share/omarchy-nvim/config/
cp -a "$XDG_CONFIG_HOME/nvim" /etc/skel/.config/
cp -a "$XDG_DATA_HOME/nvim" /etc/skel/.local/share/
rm -rf /etc/skel/.local/share/nvim/site/*
ln -sfn "../../../../.local/state/omarchy/current/theme/neovim.lua" \
  /etc/skel/.config/nvim/lua/plugins/theme.lua
install -m 0755 "$source_dir/pkgbuilds/omarchy-nvim/omarchy-nvim-setup" /usr/bin/omarchy-nvim-setup
ln -sfn omarchy-nvim-setup /usr/bin/omarchy-nvim-refresh
