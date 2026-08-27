# Repository Guidelines

## Project Structure & Module Organization

- `recipes/recipe.yml` defines the BlueBuild image, packages, services, files,
  and Flatpaks.
- `files/` contains files installed into the image, including system scripts,
  adapters, configuration, and systemd units.
- `scripts/` contains repository or image-build helpers, such as the Omarchy
  pin updater.
- `tests/` contains executable Bash tests for the recipe and runtime behavior.
- `Containerfile` is generated for local Podman builds; keep recipe changes in
  `recipes/recipe.yml` unless generated output must be inspected.

## Build, Test, and Development Commands

```bash
bluebuild generate -o Containerfile recipes/recipe.yml
podman build -t obsidian-blue .
```

Run the full local test set with:

```bash
for test in tests/*.sh; do bash "$test"; done
```

Update the pinned Omarchy release with `scripts/update-omarchy.sh VERSION`,
then review the changed version and checksum files.

## Coding Style & Naming Conventions

- Use Bash with `#!/usr/bin/env bash`, `set -euo pipefail`, quoted paths, and
  lowercase `snake_case` locals.
- Keep installed executable names and paths lowercase, descriptive, and under
  the existing `obsidian-blue` namespace where appropriate.
- Preserve YAML indentation and existing module ordering in `recipe.yml`.
- Run `bash -n` on changed shell files; no formatter or linter is configured.

## Testing Guidelines

Tests are standalone Bash scripts using temporary directories and standard
Unix tools; do not add a framework for unit-sized checks.

Name tests `tests/test-*.sh` and cover behavior or recipe invariants. Pull
requests must pass `tests/validate-recipe.sh`, browser-launcher, menu, and
migration tests in CI.

## Commit & Pull Request Guidelines

Use imperative Conventional Commit subjects, for example `fix(packages): ...`,
`test(curl): ...`, or `refactor(migration): ...`.

Pull requests should explain the user-visible or image-build impact, list test
commands run, and include relevant issue links or screenshots for UI changes.
Keep unrelated recipe, package, and configuration changes separate.

## Security & Configuration Tips

Do not commit private signing material; `cosign.pub` is public, while signing
secrets belong in GitHub Actions secrets. Keep downloaded Omarchy and font
artifacts pinned and checksum-verified.
