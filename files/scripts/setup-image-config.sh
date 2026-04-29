#!/usr/bin/env bash
# setup-image-config.sh
#
# Runs at image build time (as root inside the container).
# Handles system-level configuration that omadora normally applies with `sudo`
# during the interactive install script.

set -euo pipefail

# ── Nautilus action icon symlinks ────────────────────────────────────────────
# The omadora file manager (Nautilus) uses icons from Adwaita as fallbacks for
# navigation actions not present in Yaru.  Create symlinks so the correct
# icons are shown in Nautilus context menus and toolbars.
if [[ -d /usr/share/icons/Yaru/scalable/actions ]]; then
    ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg \
        /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
    ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg \
        /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg
    gtk-update-icon-cache /usr/share/icons/Yaru 2>/dev/null || true
fi

# ── Ensure SDDM wins as the display manager ─────────────────────────────────
# On an ostree/bootc system, systemd unit symlinks under /etc/systemd/system/
# are part of the mutable /etc layer.  The wayblue base has greetd enabled
# there (display-manager.service → greetd.service).  When an existing user
# upgrades, ostree's 3-way merge treats those symlinks as "user state" and
# preserves them even though we mask greetd in the image — so greetd would
# keep winning as display-manager.service.
#
# Explicitly writing the display-manager.service symlink here (image build
# time) puts it in the new image's /etc baseline.  A matching tmpfiles rule in
# /usr/lib/tmpfiles.d keeps rebased systems aligned when their mutable /etc
# preserves wayblue's old display-manager.service -> greetd.service link.
mkdir -p /etc/systemd/system
ln -sf /usr/lib/systemd/system/sddm.service \
    /etc/systemd/system/display-manager.service
# Remove the old greetd wants symlink if it survived from the base image.
rm -f /etc/systemd/system/multi-user.target.wants/greetd.service

# Ensure SDDM uses obsidian-blue's theme even if the wayblue base ships a later
# /etc/sddm.conf.d drop-in.  Keep /etc as a symlink to the image-owned /usr
# config so future image updates change the theme config atomically.
mkdir -p /etc/sddm.conf.d
ln -sf /usr/lib/sddm/sddm.conf.d/90-obsidian-blue-wayland.conf \
    /etc/sddm.conf.d/90-obsidian-blue-wayland.conf
ln -sf /usr/lib/sddm/sddm.conf.d/99-obsidian-blue-theme.conf \
    /etc/sddm.conf.d/99-obsidian-blue-theme.conf

echo "Image system config applied."
