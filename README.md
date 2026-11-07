# obsidian-blue

An immutable Fedora Atomic image with the Omarchy Quattro desktop and a developer workstation layer.

The image is built for x86-64. ARM Limine recovery and CPPC power-profile migrations are not yet supported.

## Model

- Omarchy `v4.5.0` is fetched from its [pinned commit](https://github.com/omacom/omarchy/commit/ac2690cd7be4f47e4a255f5e2e78d904d436b068)
  and verified by SHA-256 during the image build.
- Canonical Omarchy configuration defaults live in `/usr/share/omarchy`; new accounts receive the OWE theme hook.
- User files under `~/.config` override the baked defaults.
- Image updates use `ujust update`; Omarchy's Arch package updater is replaced by an image adapter.
- Weekly automation opens a pull request when a new stable Omarchy release exists.
- JetBrainsMono Nerd Font is fetched from its pinned release and checksum for visual parity.
- Omarchy applications are installed from the restricted, signed `kammer/omadora` Fedora COPR;
  titlebars are built from pinned source against the image's Hyprland headers.
- FFmpeg development headers come from the restricted Negativo17 repository, matching the base image's FFmpeg libraries.

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

The image omits Omarchy 4.5 optional preinstalls: web apps, TUI launchers,
Pinta, Moonlight, Obsidian, LibreOffice, Monologue, Hype, and Signed.
New accounts opt out of Omarchy default mise tools. Existing accounts receive
the preinstall opt-out marker through the migration notification; their personal
tools, launchers (including Codex), and installed Flatpaks are preserved.

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

Updates are manual. Update the Omarchy pin with `scripts/update-omarchy.sh VERSION`.
