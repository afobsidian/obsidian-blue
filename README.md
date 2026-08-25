# obsidian-blue

An immutable Fedora Atomic image with the Omarchy Quattro desktop and a developer workstation layer.

## Model

- Omarchy `v4.0.0` is fetched from its pinned commit and verified by SHA-256 during the image build.
- Canonical Omarchy defaults live in `/usr/share/omarchy` and `/etc/skel`.
- User copies live under `~/.config` and remain mutable after the first migration.
- Image updates use `ujust update`; Omarchy's Arch package updater is replaced by an image adapter.
- Weekly automation opens a pull request when a new stable Omarchy release exists.

Existing users get a one-time backup under `~/.local/state/obsidian-blue/backups/` before Quattro replaces
desktop configuration.
Later image upgrades do not replace user edits.

## Developer tools

The image includes Podman with a Docker-compatible CLI, Podman Compose, GitHub CLI, Neovim, `fd`, `rg`,
`nmtui`, Tailscale, `perf`, `nc`, compilers, Mise, tmux, and common diagnostics.
VS Code, kubectl, and Helm are intentionally absent.

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

Select `Omarchy (Hyprland uwsm)` in SDDM.

## Build

```bash
bluebuild generate -o Containerfile recipes/recipe.yml
podman build -t obsidian-blue .
```

Update the Omarchy pin with `scripts/update-omarchy.sh VERSION`.
