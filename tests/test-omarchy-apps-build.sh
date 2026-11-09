#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin"
cp "$repo/files/scripts/install-omarchy-apps.sh" "$root/"
printf source >"$root/source"
printf '%s  https://example.invalid/owe.src.rpm\n' "$(sha256sum "$root/source" | cut -d " " -f1)" >"$root/omarchy-apps-sources.sha256"
cat >"$root/bin/curl" <<'MOCK'
#!/bin/bash
printf source >"${@: -1}"
MOCK
cat >"$root/bin/rpm" <<'MOCK'
#!/bin/bash
build_root="${2#_topdir }"
printf 'BuildRequires: ffmpeg\n' >"$build_root/SPECS/owe.spec"
MOCK
cat >"$root/bin/rpmbuild" <<'MOCK'
#!/bin/bash
set -eu
build_root="${2#_topdir }"
grep -Fxq 'BuildRequires: ffmpeg-free' "$build_root/SPECS/owe.spec"
mkdir -p "$build_root/RPMS/x86_64"
touch "$build_root/RPMS/x86_64/owe.fc46.rpm"
printf built >>"$TEST_ROOT/built"
MOCK
cat >"$root/bin/dnf" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >>"$TEST_ROOT/dnf-calls"
if [[ ${MOCK_BUILDDEP_FAIL:-0} == 1 && "$*" == *builddep* ]]; then exit 1; fi
MOCK
chmod +x "$root/bin/"*
export TEST_ROOT="$root"
PATH="$root/bin:$PATH" bash "$root/install-omarchy-apps.sh"
test "$(cat "$root/built")" = built
grep -q 'owe.fc46.rpm' "$root/dnf-calls"
rm "$root/built"
if MOCK_BUILDDEP_FAIL=1 PATH="$root/bin:$PATH" bash "$root/install-omarchy-apps.sh"; then exit 1; fi
test ! -e "$root/built"
sed -i 's/^[[:xdigit:]]*/0000000000000000000000000000000000000000000000000000000000000000/' "$root/omarchy-apps-sources.sha256"
if PATH="$root/bin:$PATH" bash "$root/install-omarchy-apps.sh"; then exit 1; fi
test ! -e "$root/built"
