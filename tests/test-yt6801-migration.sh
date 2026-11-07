#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin" "$root/omarchy/migrations" "$root/home"
cp "$repo/files/scripts/omarchy-migrations/1788279117.sh" "$root/omarchy/migrations/"
printf '#!/bin/bash\nexit "${LSPCI_STATUS:-0}"\n' >"$root/bin/lspci"
printf '#!/bin/bash\nexit 0\n' >"$root/bin/rpm"
printf '#!/bin/bash\nexit 0\n' >"$root/bin/lsmod"
chmod +x "$root/bin/"*
export HOME="$root/home" XDG_STATE_HOME="$root/home/.local/state" OMARCHY_PATH="$root/omarchy" PATH="$root/bin:$PATH"
adapter="$repo/files/usr/libexec/obsidian-blue/omarchy-adapters/omarchy-migrate"
if LSPCI_STATUS=1 "$adapter"; then exit 1; fi
test ! -e "$HOME/.local/state/omarchy/migrations/1788279117.sh"
"$adapter"
test -f "$HOME/.local/state/omarchy/migrations/1788279117.sh"
test -z "$("$adapter")"
