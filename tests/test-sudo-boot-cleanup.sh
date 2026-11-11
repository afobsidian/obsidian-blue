#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin"
cp "$repo/tests/fixtures/omarchy-sudo-boot-cleanup" "$root/bin/omarchy-sudo-passwordless"
(cd "$root" && git apply --recount <"$repo/files/patches/omarchy-sudo-passwordless.patch")
source <(sed -n '/^verify_boot_cleanup() {$/,/^}$/p' "$root/bin/omarchy-sudo-passwordless")

BOOT_CLEANUP_FILE="$root/cleanup.conf"
REMOVAL_BLOCKER="$root/removing"
INSTALLED_SELF="$root/bin/omarchy-sudo-passwordless"
verify_root_path() { [[ -f "$1" && ! -L "$1" ]]; }
function /usr/bin/findmnt() { printf '%s\n' "$mount_options_mock"; }
mount_options_mock=ro,relatime
cp "$repo/files/etc/tmpfiles.d/omarchy-nopasswd-sudo.conf" "$BOOT_CLEANUP_FILE"
verify_boot_cleanup
mount_options_mock=rw,relatime
! verify_boot_cleanup
mount_options_mock=ro,relatime
touch "$REMOVAL_BLOCKER"
! verify_boot_cleanup
rm "$REMOVAL_BLOCKER"
printf '%s\n' 'r! /etc/sudoers.d/*' >"$BOOT_CLEANUP_FILE"
! verify_boot_cleanup
rm "$BOOT_CLEANUP_FILE"
! verify_boot_cleanup
ln -s "$repo/files/etc/tmpfiles.d/omarchy-nopasswd-sudo.conf" "$BOOT_CLEANUP_FILE"
! verify_boot_cleanup
rm "$BOOT_CLEANUP_FILE"
cp "$repo/files/etc/tmpfiles.d/omarchy-nopasswd-sudo.conf" "$BOOT_CLEANUP_FILE"
rm "$INSTALLED_SELF"
! verify_boot_cleanup
