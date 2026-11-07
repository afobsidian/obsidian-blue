#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin" "$root/home/.config/omarchy/hooks/theme-set.d"
printf '#!/bin/bash\nexit 0\n' >"$root/bin/omarchy-pkg-add"
printf '#!/bin/bash\necho installed >"$HOME/.config/omarchy/hooks/theme-set.d/10-owe-sync"\n' >"$root/bin/omarchy-hook-install"
printf '#!/bin/bash\n[[ "$*" != *is-active* ]]\n' >"$root/bin/systemctl"
chmod +x "$root/bin/"*
export HOME="$root/home" PATH="$root/bin:$PATH"
hook="$HOME/.config/omarchy/hooks/theme-set.d/10-owe-sync"
printf 'custom\n' >"$hook"
bash -euo pipefail "$repo/files/scripts/omarchy-migrations/1789764927.sh"
test "$(cat "$hook")" = custom
rm "$hook"
bash -euo pipefail "$repo/files/scripts/omarchy-migrations/1789764927.sh"
test "$(cat "$hook")" = installed
bash -euo pipefail "$repo/files/scripts/omarchy-migrations/1789764927.sh"
test "$(cat "$hook")" = installed
