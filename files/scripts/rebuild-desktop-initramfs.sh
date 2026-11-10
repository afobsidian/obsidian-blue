#!/usr/bin/env bash
set -euo pipefail

# Rebuild the image kernel, never the kernel of the container host.
kernel_images=(/usr/lib/modules/*/vmlinuz)
[[ -f "${kernel_images[0]}" ]] || { echo "Image kernel is absent" >&2; exit 1; }
for kernel_image in "${kernel_images[@]}"; do
  kernel_dir="${kernel_image%/vmlinuz}"
  kernel_version="${kernel_dir##*/}"
  dracut --force --no-hostonly --kver "$kernel_version" "$kernel_dir/initramfs.img"
  modules="$(lsinitrd -m "$kernel_dir/initramfs.img")"
  for module in crypt systemd-cryptsetup plymouth drm; do
    grep -Fxq "$module" <<<"$modules" || { echo "Initramfs is missing $module" >&2; exit 1; }
  done
  contents="$(lsinitrd "$kernel_dir/initramfs.img")"
  grep -Eq '/i915\.ko(\.|$)' <<<"$contents" || { echo "Initramfs is missing i915" >&2; exit 1; }
  grep -Eq '/plymouth/label-(freetype|pango)\.so' <<<"$contents" || { echo "Initramfs is missing Plymouth label rendering" >&2; exit 1; }
  grep -Fq 'omarchy.plymouth' <<<"$contents" || { echo "Initramfs is missing the unlock theme" >&2; exit 1; }
done
