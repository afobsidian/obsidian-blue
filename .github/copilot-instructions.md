# obsidian-blue Copilot instructions

- This repository builds a custom BlueBuild Fedora Atomic image.
- Treat `recipes/recipe.yml` as the source of truth for image composition.
- Do not hand-edit `Containerfile`. It is generated output and must only change via `bluebuild generate -o Containerfile recipes/recipe.yml`.
- When a task changes packages, repos, systemd services, Flatpaks, or build modules, edit `recipes/recipe.yml` and any supporting files under `files/` rather than patching generated artifacts.
- Keep generated artifacts in sync with source inputs. After changing the recipe or supporting files that affect the image, regenerate `Containerfile` before considering the task complete.
- Preserve comments in `recipes/recipe.yml` that explain why packages are added, removed, pinned, or replaced from the wayblue base.
- Keep custom DNF repo definitions in `files/`, and reference them from the recipe instead of embedding repo file contents elsewhere.
- Prefer validating image-definition changes with `bluebuild generate -o Containerfile recipes/recipe.yml` and then `podman build -t obsidian-blue .` when local container tooling is available.
- For GitHub Actions image changes, keep `.github/workflows/build.yml` aligned with the recipe-driven build flow.
- Trust these repository instructions first for image-layout questions and only search more broadly when the instructions and recipe do not answer the task.
