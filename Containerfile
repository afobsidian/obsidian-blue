ARG BASE_IMAGE="ghcr.io/wayblueorg/hyprland-nvidia-open@sha256:7b1d673a689ab73f9dc6a644cd89b440fb081a7c753a55ff28d935113a9ed575"
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
ARG BASE_IMAGE="ghcr.io/wayblueorg/hyprland-nvidia-open"
ARG FORCE_COLOR=1
ARG CLICOLOR_FORCE=1
ARG RUST_LOG_STYLE=always
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
/tmp/scripts/run_module.sh 'dnf' '{"type":"dnf","repos":{"cleanup":true,"files":["https://download.docker.com/linux/fedora/docker-ce.repo","sdegler-hyprland.repo","jdxcode-mise.repo","vscode.repo"]},"install":{"install-weak-deps":false,"packages":["hyprland","xdg-desktop-portal-hyprland","hyprpaper","hyprlock","hypridle","hyprland-qtutils","hyprland-plugins","hyprpicker","hyprshot","hyprpolkitagent","hyprsunset","hyprland-contrib","satty","alacritty","bat","bind-utils","btop","cascadia-code-nf-fonts","cascadia-mono-nf-fonts","chromium","clang","dbus-tools","du-dust","evince","fastfetch","fcitx5","fcitx5-configtool","fcitx5-gtk","fcitx5-qt","fontawesome-fonts-all","gnome-calculator","gnome-keyring","gnome-themes-extra","google-noto-fonts-common","gum","gvfs-mtp","gvfs-smb","iwd","libxkbcommon-utils","mako","mise","nautilus","pipewire-devel","pipx","plocate","plymouth","power-profiles-daemon","sushi","swaybg","tldr","usbutils","uwsm","wf-recorder","whois","wiremix","xdg-desktop-portal-gtk","xdg-terminal-exec","xdg-user-dirs","xmlstarlet","yaru-icon-theme","zoxide","swappy","cliphist","SwayNotificationCenter","mpv","nwg-look","qt5ct","qt6ct","kvantum","wlogout","ImageMagick","tumbler","yad","yt-dlp","imv","python3-gobject","python3-i3ipc","gtk-layer-shell","python3-build","python3-installer","python3-setuptools","python3-wheel","cargo","rust","gcc","docker-ce","docker-ce-cli","containerd.io","docker-buildx-plugin","docker-compose-plugin","code","kubectl","helm","gh","neovim","ripgrep","fd-find","jq","yq","zsh","fish","perf","sysprof"]},"remove":{"packages":["wlsunset","dunst"]}}'
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
/tmp/scripts/run_module.sh 'systemd' '{"type":"systemd","system":{"enabled":["docker.socket","docker.service","podman.socket"]},"user":{"enabled":["podman.socket"]}}'
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
/tmp/scripts/run_module.sh 'files' '{"type":"files","files":[{"source":"omadora","destination":"/etc/skel/.local/share/omadora"}]}'
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
/tmp/scripts/run_module.sh 'script' '{"type":"script","scripts":["install-upstream-tools.sh"]}'
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
/tmp/scripts/run_module.sh 'dnf' '{"type":"dnf","remove":{"packages":["python3-build","python3-installer","python3-setuptools","python3-wheel","cargo","rust","gcc","clang","pipewire-devel"]}}'
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
/tmp/scripts/run_module.sh 'default-flatpaks' '{"type":"default-flatpaks","configurations":[{"notify":true,"scope":"system","repo":{"url":"https://dl.flathub.org/repo/flathub.flatpakrepo","name":"flathub"},"install":["com.github.wwmm.easyeffects","io.podman_desktop.PodmanDesktop","org.gnome.Boxes"]}]}'
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
LABEL org.blue-build.build-id="53a41dc5-7976-4394-ba77-a8be15dfd8e6"
LABEL org.opencontainers.image.base.digest="sha256:7b1d673a689ab73f9dc6a644cd89b440fb081a7c753a55ff28d935113a9ed575"
LABEL org.opencontainers.image.base.name="ghcr.io/wayblueorg/hyprland-nvidia-open:latest"
LABEL org.opencontainers.image.created="2026-04-22T02:13:32.041897807+00:00"
LABEL org.opencontainers.image.description="Custom immutable Fedora Atomic image. wayblue hyprland base + omadora Hyprland desktop + bluefin-dx developer tooling + extra opinionated Hyprland ecosystem packages."
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.title="obsidian-blue"