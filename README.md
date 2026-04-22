# obsidian-blue

A custom immutable Fedora Atomic OS image built with [BlueBuild](https://blue-build.org/).

**Lineage:**

```text
Fedora Atomic
  └── ghcr.io/wayblueorg/hyprland-nvidia-open   (wayblue base)
        └── obsidian-blue              (this image)
```

## What's included

### From wayblue common base (already provided, not re-added)

`rofi-wayland` · `wofi` · `fzf` · `just` · `distrobox` · `wl-clipboard` · `pavucontrol` · `playerctl` · `pamixer` · `brightnessctl` · `blueman` · `slurp` · `grim` · `dunst`_· `wlsunset`_ · `kanshi` · `wlr-randr` · `thunar` · `thunar-archive-plugin` · `thunar-volman` · `xarchiver` · `wireplumber` · `pipewire` · `qt5-qtwayland` · `qt6-qtwayland` · `vim` · and more

> \* `dunst` is replaced by `SwayNotificationCenter` and `wlsunset` is replaced by `hyprsunset` — both removed in this image.

### From wayblue hyprland image (already provided, not re-added)

`hyprland` · `waybar` · `kitty` · `hyprpaper` · `hyprlock` · `hypridle` · `xdg-desktop-portal-hyprland` · `hyprland-qtutils` — all from the `solopasha/hyprland` COPR, which wayblue enables.

---

### Added: Extra Hyprland ecosystem

| Package            | Purpose                                                   |
| ------------------ | --------------------------------------------------------- |
| `hyprland-plugins` | Official plugins (border++, hyprexpo, hyprtrails, …)      |
| `hyprpicker`       | Colour picker                                             |
| `hyprshot`         | Screenshot utility                                        |
| `hyprpolkitagent`  | Polkit authentication agent                               |
| `hyprsunset`       | Blue-light filter — replaces `wlsunset` from wayblue base |
| `hyprland-contrib` | Community scripts (grimblast, etc.)                       |
| `satty`            | Screenshot annotation                                     |

### Added: Modern Hyprland-Dots dependencies

Packages not already in the wayblue base:

| Package(s)                    | Purpose                                                    |
| ----------------------------- | ---------------------------------------------------------- |
| `swappy`                      | Screenshot editor (`grim` + `slurp` already in base)       |
| `cliphist`                    | Clipboard manager (`wl-clipboard` backend already in base) |
| `SwayNotificationCenter`      | Notification daemon — replaces `dunst` from wayblue base   |
| `mpv`                         | Media player                                               |
| `nwg-look`                    | GTK settings GUI                                           |
| `qt6ct` · `qt5ct` · `kvantum` | QT app theming                                             |
| `wallust`                     | Colour palette generator from wallpaper                    |
| `wlogout`                     | Logout / power menu                                        |
| `ImageMagick`                 | Image manipulation for wallpaper scripts                   |
| `nwg-displays`                | Monitor management GUI                                     |
| `tumbler`                     | Thumbnail service for Thunar                               |
| `yad` · `yt-dlp`              | Dialog boxes and video downloader used by KooL scripts     |
| `imv`                         | Image viewer                                               |

`wallust` and `nwg-displays` are installed from upstream source during the image build because they are not available from the enabled Fedora repos used by this recipe.

### Added: Developer tooling (inspired by bluefin-dx)

| Package(s)                          | Purpose                                               |
| ----------------------------------- | ----------------------------------------------------- |
| `docker-ce` + compose + buildx      | Container runtime (default for VS Code devcontainers) |
| `code`                              | VS Code with devcontainers extension                  |
| `kubectl` · `helm`                  | Kubernetes tooling                                    |
| `gh` · `lazygit` · `neovim`         | Git and editor tooling                                |
| `ripgrep` · `fd-find` · `jq` · `yq` | CLI utilities (`fzf` already in base)                 |
| `zsh` · `fish`                      | Shells                                                |
| `perf` · `sysprof`                  | System performance profiling                          |

`lazygit` is installed from the upstream GitHub release during the image build because it is not available from the enabled Fedora repos used by this recipe.

> `distrobox` and `just` are already provided by the wayblue base.

### Flatpaks (installed on first boot)

EasyEffects, Podman Desktop, GNOME Boxes.

---

## Builds

Images are built and pushed automatically every **Monday at 04:00 UTC** via GitHub Actions, as well as on every push to `main`. This ensures base-image and package updates are picked up weekly.

---

## Installation

### First rebase (unsigned, to get signing keys)

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/afobsidian/obsidian-blue:latest
systemctl reboot
```

### Second rebase (signed)

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/afobsidian/obsidian-blue:latest
systemctl reboot
```

### Post-install (one-time)

```bash
# Add yourself to the docker group
sudo usermod -aG docker $USER

# Nvidia GPU only — add kernel args:
rpm-ostree kargs \
  --append-if-missing=rd.driver.blacklist=nouveau \
  --append-if-missing=modprobe.blacklist=nouveau \
  --append-if-missing=nvidia-drm.modeset=1 \
  --append-if-missing=nvidia-drm.fbdev=1
```

> **Nvidia GPU?** This recipe already uses `ghcr.io/wayblueorg/hyprland-nvidia-open`. Change `base-image` only if you want a different wayblue variant.

---

## Building locally

```bash
# Install BlueBuild CLI
podman run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash

# Generate Containerfile and build
bluebuild generate -o Containerfile recipes/recipe.yml
podman build -t obsidian-blue .
```

---

## Repository setup

1. Create a new repo from the [BlueBuild template](https://github.com/blue-build/template)
2. Replace `recipe.yml` with the one from this project
3. Add `.github/workflows/build.yml`
4. Generate a cosign keypair (`cosign generate-key-pair`) and add the private key as `SIGNING_SECRET` in your repo secrets
5. Push to `main` — GitHub Actions will build and push to `ghcr.io/afobsidian/obsidian-blue:latest`
