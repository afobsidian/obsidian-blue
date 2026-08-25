ARG BASE_IMAGE="ghcr.io/wayblueorg/hyprland@sha256:efc40c3544c7a9a379b75561c22a50d7342c7d72c30452d26fde8ef6d3ffb436"
FROM "${BASE_IMAGE}" AS obsidian-blue

# This stage is responsible for holding onto
# your config without copying it directly into
# the final image
FROM scratch AS stage-files
COPY ./files /files

# Bins to install
# These are basic tools that are added to all images.
# Generally used for the build process. We use a multi
# stage process so that adding the bins into the image
# can be added to the ostree commits.
FROM scratch AS stage-bins
COPY --from=ghcr.io/sigstore/cosign/cosign:v3.0.5 \
  /ko-app/cosign /bins/cosign
COPY --from=ghcr.io/blue-build/cli:latest-installer \
  /out/bluebuild /bins/bluebuild
# Keys for pre-verified images
# Used to copy the keys into the final image
# and perform an ostree commit.
#
# Currently only holds the current image's
# public key.
FROM scratch AS stage-keys
COPY cosign.pub /keys/obsidian-blue.pub


# Main image
FROM obsidian-blue
ARG TARGETARCH
ARG RECIPE=recipes/recipe.yml
ARG IMAGE_REGISTRY=localhost
ARG BB_BUILD_FEATURES=""
ARG CONFIG_DIRECTORY="/tmp/files"
ARG MODULE_DIRECTORY="/tmp/modules"
ARG IMAGE_NAME="obsidian-blue"
ARG BASE_IMAGE="ghcr.io/wayblueorg/hyprland"
# Key RUN
RUN --mount=type=bind,from=stage-keys,src=/keys,dst=/tmp/keys \
  mkdir -p /etc/pki/containers/ \
  && cp /tmp/keys/* /etc/pki/containers/
# Bin RUN
RUN --mount=type=bind,from=stage-bins,src=/bins,dst=/tmp/bins \
  mkdir -p /usr/bin/ \
  && cp /tmp/bins/* /usr/bin/
RUN --mount=type=bind,from=ghcr.io/blue-build/nushell-image:default,src=/nu,dst=/tmp/nu \
  mkdir -p /usr/libexec/bluebuild/nu \
  && cp -r /tmp/nu/* /usr/libexec/bluebuild/nu/
RUN \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/scripts/,Z \
  /scripts/pre_build.sh

# Module RUNs
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/script:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'script' '{"type":"script","scripts":["clear-rpmfusion-dnf-cache.sh","swap-hyprland-copr.sh"]}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/dnf:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'dnf' '{"type":"dnf","repos":{"cleanup":true,"files":["lionheartp-hyprland.repo"]},"remove":{"auto-remove":false,"packages":["hyprland","hyprland-git","hyprland-plugins","hyprland-plugins-git","waybar","waybar-git","dunst","mako","greetd","gtkgreet"]},"install":{"allow-erasing":true,"install-weak-deps":false,"packages":["hyprland","hyprland-uwsm","uwsm","quickshell","hypridle","hyprpicker","hyprpolkitagent","hyprsunset","hyprland-guiutils","hyprland-qt-support","xdg-desktop-portal-hyprland"]}}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/dnf:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'dnf' '{"type":"dnf","repos":{"cleanup":true,"files":["jdxcode-mise.repo","starship.repo"]},"install":{"skip-unavailable":true,"skip-broken":true,"install-weak-deps":false,"packages":["ImageMagick","NetworkManager-tui","alacritty","alsa-utils","avahi","bash-completion","bat","bluez","bluez-tools","bolt","brightnessctl","btop","chromium","clang","cups","cups-browsed","cups-filters","cups-pdf","dbus-tools","ddcutil","dosfstools","dua-cli","evince","exfatprogs","eza","fastfetch","fcitx5","fcitx5-configtool","fcitx5-gtk","fcitx5-qt","fd-find","ffmpeg-free","ffmpegthumbnailer","foot","fzf","gh","git","gnome-disk-utility","gnome-keyring","gnome-themes-extra","google-noto-color-emoji-fonts","google-noto-sans-cjk-fonts","grim","gum","gvfs-mtp","gvfs-nfs","gvfs-smb","imv","inetutils","inotify-tools","inxi","iwd","jq","kitty","less","libsecret","libxkbcommon-utils","lua","luarocks","man-db","mise","mpv","nautilus","nautilus-python","neovim","nmap-ncat","pamixer","perf","perl-JSON-PP","playerctl","plocate","plymouth","podman","podman-compose","podman-docker","podman-tui","power-profiles-daemon","python3-gobject","qrencode","ripgrep","ruby","sddm","slurp","socat","starship","sushi","sysprof","system-config-printer","tailscale","tesseract","tesseract-langpack-eng","tldr","tmux","udiskie","unzip","usbutils","whois","wireplumber","wl-clipboard","wtype","xdg-desktop-portal-gtk","xdg-terminal-exec","xdg-user-dirs","xdg-utils","yaru-icon-theme","yq","yt-dlp","zbar","zoxide","zsh"]},"remove":{"packages":["Thunar","thunar-archive-plugin","thunar-volman","tuned-ppd","wlsunset"]}}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/files:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'files' '{"type":"files","files":[{"source":"usr","destination":"/usr"},{"source":"etc","destination":"/etc"}]}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/script:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'script' '{"type":"script","scripts":["install-omarchy-quattro.sh","setup-image-config.sh","validate-omarchy-image.sh"]}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/systemd:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'systemd' '{"type":"systemd","system":{"enabled":["NetworkManager.service","avahi-daemon.service","bluetooth.service","cups.service","podman.socket","sddm.service","tailscaled.service"],"masked":["greetd.service","systemd-remount-fs.service"]},"user":{"enabled":["podman.socket"]}}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/default-flatpaks:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'default-flatpaks' '{"type":"default-flatpaks","configurations":[{"notify":true,"scope":"system","repo":{"url":"https://dl.flathub.org/repo/flathub.flatpakrepo","name":"flathub"},"install":["com.github.PintaProject.Pinta","com.github.xournalpp.xournalpp","com.moonlight_stream.Moonlight","com.obsproject.Studio","io.podman_desktop.PodmanDesktop","md.obsidian.Obsidian","org.kde.kdenlive","org.libreoffice.LibreOffice","org.localsend.localsend_app"]}]}'
RUN \
--mount=type=bind,from=stage-files,src=/files,dst=/tmp/files,rw \
--mount=type=bind,from=ghcr.io/blue-build/modules/signing:latest,src=/modules,dst=/tmp/modules,rw \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/tmp/scripts/,Z \
--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/zypp,id=zypper-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apk,id=apk-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/apt,id=apt-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/var/cache/pacman,id=pacman-cache-obsidian-blue-latest-stage-obsidian-blue \
--mount=type=cache,sharing=locked,dst=/usr/lib/sysimage/cache/pacman,id=pacman-sysimage-cache-obsidian-blue-latest-stage-obsidian-blue \
/tmp/scripts/run_module.sh 'signing' '{"type":"signing"}'

RUN \
--mount=type=bind,src=.bluebuild-scripts_6fc443c6,dst=/scripts/,Z \
  /scripts/post_build.sh

# Labels are added last since they cause cache misses with buildah
LABEL io.artifacthub.package.readme-url="https://raw.githubusercontent.com/blue-build/cli/main/README.md"
LABEL org.blue-build.build-id="d799263d-4096-4355-b5e0-c2b4db9fae33"
LABEL org.opencontainers.image.base.digest="sha256:efc40c3544c7a9a379b75561c22a50d7342c7d72c30452d26fde8ef6d3ffb436"
LABEL org.opencontainers.image.base.name="ghcr.io/wayblueorg/hyprland:latest"
LABEL org.opencontainers.image.created="2026-08-25T03:59:50.348754006+00:00"
LABEL org.opencontainers.image.description="Omarchy Quattro on Fedora Atomic with a mutable user configuration layer."
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.title="obsidian-blue"