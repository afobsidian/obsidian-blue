#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_root="$(mktemp -d)"
trap 'rm -rf "$build_root"' EXIT
mkdir -p "$build_root"/{SOURCES,SPECS,BUILD,BUILDROOT,RPMS,SRPMS}
dnf -y install rpm-build dnf5-plugins
export CARGO_BUILD_JOBS=2

# Rebuild pinned Fedora source packages against Rawhide; never install fc44 binaries.
while read -r checksum url; do
  source_rpm="$build_root/${url##*/}"
  curl -fsSL --retry 3 "$url" -o "$source_rpm"
  printf '%s  %s\n' "$checksum" "$source_rpm" | sha256sum --check --status
  rpm --define "_topdir $build_root" -i "$source_rpm"
done < "$script_dir/omarchy-apps-sources.sha256"

# Fedora supplies the free codec build; Wayblue previously supplied Negativo17.
sed -i -E 's/^(BuildRequires:[[:space:]]+)ffmpeg$/\1ffmpeg-free/' "$build_root/SPECS/owe.spec"
for spec in "$build_root"/SPECS/*.spec; do
  dnf -y builddep "$spec"
  rpmbuild --define "_topdir $build_root" --define '_smp_mflags -j2' -bb "$spec"
done
dnf -y install "$build_root"/RPMS/*/*.rpm
