#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir "$root/bin"
export TEST_ROOT="$root" PATH="$root/bin:$PATH"
cat >"$root/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_ROOT/downloads"
[[ "${FAIL_ALL:-0}" == 0 ]] || exit 22
[[ "$*" != *mirrors.rpmfusion.org* ]] || exit 22
printf 'fixture\n' >"${!#}"
EOF
cat >"$root/bin/sha256sum" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == '--check --status' ]] || exit 1
read -r hash file
[[ "$hash" =~ ^[a-f0-9]{64}$ && -s "$file" ]] || exit 1
[[ "${BAD_HASH:-0}" == 0 ]] || exit 1
touch "$TEST_ROOT/verified"
EOF
cat >"$root/bin/dnf" <<'EOF'
#!/usr/bin/env bash
test -e "$TEST_ROOT/verified" || exit 1
touch "$TEST_ROOT/installed"
EOF
chmod +x "$root/bin/"*

bash "$repo/files/scripts/enable-rpmfusion-free.sh"
test -e "$root/installed"
grep -Fq repo.fedora.md "$root/downloads"
rm "$root/verified" "$root/installed"
if BAD_HASH=1 bash "$repo/files/scripts/enable-rpmfusion-free.sh"; then exit 1; fi
test ! -e "$root/installed"
if FAIL_ALL=1 bash "$repo/files/scripts/enable-rpmfusion-free.sh"; then exit 1; fi
test ! -e "$root/installed"
