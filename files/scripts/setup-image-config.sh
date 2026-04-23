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

echo "Image system config applied."
