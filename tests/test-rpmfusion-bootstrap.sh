#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir "$root/bin"
export TEST_ROOT="$root" PATH="$root/bin:$PATH"
cat >"$root/bin/dnf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == -y && "$2" == --setopt=reposdir=* && "$3" == install && "$4" == rpmfusion-free-release ]]
config="${2#--setopt=reposdir=}/rpmfusion-bootstrap.repo"
grep -Fxq 'gpgcheck=1' "$config"
grep -Fq 'development/rawhide/Everything/$basearch/os/' "$config"
key="$(sed -n 's/^gpgkey=file:\/\/\(.*\)/\1/p' "$config")"
[[ "$(sha256sum "$key" | cut -d' ' -f1)" == 10fc0a3e1a0307e8088357a31a9c5e4e3d9f9e0b01db2b03b5790d949a47f3b3 ]]
exit "${DNF_STATUS:-0}"
EOF
chmod +x "$root/bin/dnf"
bash "$repo/files/scripts/enable-rpmfusion-free.sh"
if DNF_STATUS=1 bash "$repo/files/scripts/enable-rpmfusion-free.sh"; then exit 1; fi
