# Repository guidance

- This repository builds the immutable BlueBuild image used on this machine. Treat `recipes/recipe.yml` as the image source of truth and regenerate `Containerfile`; do not hand-edit it.
- `../dotfiles` is the user configuration overlay applied on top of this image. Inspect both repositories and the deployed files under `~/.config` when diagnosing desktop behavior.
- Keep packages, system services, drivers, and immutable defaults here. Keep user-session policy and personal Hyprland configuration in `../dotfiles`.
- Monique is installed and globally enabled as an image feature. User configuration may use it or provide an independent monitor fallback.
