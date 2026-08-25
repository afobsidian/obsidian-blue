#!/usr/bin/env bash

set -euo pipefail

mkdir -p /etc/systemd/system
ln -sfn /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service
rm -f /etc/systemd/system/multi-user.target.wants/greetd.service

if [[ -d /usr/share/icons/Yaru/scalable/actions ]]; then
  ln -sfn /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg \
    /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
  ln -sfn /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg \
    /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg
fi
