#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir "$root/bin"
export TEST_ROOT="$root" PATH="$root/bin:$PATH"
cat >"$root/bin/rpm" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "-q --whatprovides liboapv.so.3()(64bit)" && "${PROVIDER_PRESENT:-0}" == 1 ]]
EOF
cat >"$root/bin/curl" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == *'/data/signed/91211fce/'* ]] || exit 1
touch "$TEST_ROOT/downloaded"
printf 'fixture\n' >"${!#}"
EOF
cat >"$root/bin/sha256sum" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == '--check --status' ]] || exit 1
read -r hash file
[[ "$hash" == 0f9544d3bf5d7ac39477e67b98e06aff74c215d292254fc8ca1c8915fc0ab553 && -s "$file" ]] || exit 1
[[ "${BAD_HASH:-0}" == 0 ]] || exit 1
touch "$TEST_ROOT/verified"
EOF
cat >"$root/bin/dnf" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == *'--setopt=localpkg_gpgcheck=True install '* && -e "$TEST_ROOT/verified" ]] || exit 1
touch "$TEST_ROOT/installed"
EOF
chmod +x "$root/bin/"*

PROVIDER_PRESENT=1 bash "$repo/files/scripts/install-openapv-compat.sh"
test ! -e "$root/downloaded"
bash "$repo/files/scripts/install-openapv-compat.sh"
test -e "$root/installed"
rm "$root/verified" "$root/installed"
if BAD_HASH=1 bash "$repo/files/scripts/install-openapv-compat.sh"; then exit 1; fi
test ! -e "$root/installed"
grep -Fq install-openapv-compat.sh "$repo/recipes/recipe.yml"
