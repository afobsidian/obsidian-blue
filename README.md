# obsidian-blue

An immutable Fedora Atomic image with the Omarchy Quattro desktop and a developer workstation layer.

## Model

- Omarchy `v4.0.2` is fetched from its [pinned commit](https://github.com/omacom/omarchy/commit/346e69e1cec6c4e8924531874af6ba010a1bc99e)
  and verified by SHA-256 during the image build.
- Canonical Omarchy defaults live in `/usr/share/omarchy` and are not copied into user config.
- User files under `~/.config` override the baked defaults.
- Image updates use `ujust update`; Omarchy's Arch package updater is replaced by an image adapter.
- Weekly automation opens a pull request when a new stable Omarchy release exists.
- JetBrainsMono Nerd Font is fetched from its pinned release and checksum for visual parity.

Existing desktop configuration is archived once under `~/.local/state/obsidian-blue/backups/`.
Quattro then starts from the image defaults until the user creates an override.

## Developer tools

The image includes Podman with a Docker-compatible CLI, Podman Compose, GitHub CLI, Neovim, `fd`, `rg`,
`nmtui`, Tailscale, `perf`, `nc`, Homebrew, compilers, Mise, tmux, and common diagnostics.
VS Code, kubectl, and Helm are intentionally absent.

Omarchy's Bash environment is the default. Add personal exports, aliases, and functions as separate
`~/.bashrc.d/*.sh` files; Fedora's stock `~/.bashrc` loads them after the baked system defaults.

## Flatpaks

Flathub is configured at system scope and curated defaults are installed on first boot.
Existing system and user Flatpaks are never removed, and more can be installed normally:

```bash
flatpak install flathub APP_ID
```

## Install

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/afobsidian/obsidian-blue:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/afobsidian/obsidian-blue:latest
systemctl reboot
```

Every Hyprland entry in SDDM starts the Omarchy session.

## Build

```bash
bluebuild generate -o Containerfile recipes/recipe.yml
podman build -t obsidian-blue .
```

Update the Omarchy pin with `scripts/update-omarchy.sh VERSION`.
