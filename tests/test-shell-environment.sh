#!/usr/bin/env bash

set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/default/bash"
printf "alias omarchy-shell-test='true'\n" >"$root/default/bash/rc"

OMARCHY_PATH="$root" bash --rcfile "$repo/files/etc/profile.d/99-omarchy-bash.sh" \
  -ic 'alias omarchy-shell-test' >/dev/null 2>&1
sh -c ". '$repo/files/etc/profile.d/99-omarchy-bash.sh'"
