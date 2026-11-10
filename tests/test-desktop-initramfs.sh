#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/modules/image-kernel" "$root/bin"
touch "$root/modules/image-kernel/vmlinuz"
sed "s|/usr/lib/modules|$root/modules|g" "$repo/files/scripts/rebuild-desktop-initramfs.sh" >"$root/rebuild.sh"
cat >"$root/bin/dracut" <<'MOCK'
#!/bin/bash
[[ "$*" == *"--no-hostonly --kver image-kernel"* ]] || exit 1
printf initramfs >"${@: -1}"
MOCK
cat >"$root/bin/lsinitrd" <<'MOCK'
#!/bin/bash
if [[ "$1" == -m ]]; then
  for module in crypt systemd-cryptsetup plymouth drm; do
    [[ "$module" == "${OMIT:-}" ]] || printf '%s\n' "$module"
  done
else
  [[ "${OMIT:-}" == i915 ]] || echo usr/lib/modules/image-kernel/kernel/drivers/gpu/drm/i915/i915.ko.xz
  [[ "${OMIT:-}" == label ]] || echo usr/lib64/plymouth/label-freetype.so
  [[ "${OMIT:-}" == theme ]] || echo usr/share/plymouth/themes/omarchy/omarchy.plymouth
fi
exit 0
MOCK
chmod +x "$root/bin/"*
PATH="$root/bin:$PATH" bash "$root/rebuild.sh"
test -s "$root/modules/image-kernel/initramfs.img"
for missing in crypt systemd-cryptsetup plymouth drm i915 label theme; do
  if OMIT="$missing" PATH="$root/bin:$PATH" bash "$root/rebuild.sh"; then exit 1; fi
done
rm "$root/modules/image-kernel/vmlinuz"
if PATH="$root/bin:$PATH" bash "$root/rebuild.sh"; then exit 1; fi
config="$repo/files/usr/lib/dracut/dracut.conf.d/60-obsidian-blue-desktop.conf"
grep -Fqx 'hostonly="no"' "$config"
grep -Fqx 'Theme=omarchy' "$repo/files/etc/plymouth/plymouthd.conf"
grep -Fq 'plymouth-plugin-script' "$repo/recipes/recipe.yml"
test "$(grep -nE 'rebuild-desktop-initramfs.sh|validate-omarchy-image.sh' "$repo/recipes/recipe.yml" | cut -d : -f2- | head -1 | xargs)" = '- rebuild-desktop-initramfs.sh'
