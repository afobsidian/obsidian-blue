#!/usr/bin/env bash

set -euo pipefail

version="${1:?usage: $0 VERSION}"
tag="v$version"
env_file="files/scripts/omarchy-version.env"
commit="$(git ls-remote https://github.com/basecamp/omarchy.git "refs/tags/$tag^{}" | cut -f1)"
[[ -n "$commit" ]] || commit="$(git ls-remote https://github.com/basecamp/omarchy.git "refs/tags/$tag" | cut -f1)"
[[ -n "$commit" ]] || { echo "Omarchy tag not found: $tag" >&2; exit 1; }

archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
curl -fsSL "https://codeload.github.com/basecamp/omarchy/tar.gz/$commit" -o "$archive"
sha256="$(sha256sum "$archive" | cut -d' ' -f1)"

sed -i \
  -e "s/^OMARCHY_VERSION=.*/OMARCHY_VERSION=$version/" \
  -e "s/^OMARCHY_COMMIT=.*/OMARCHY_COMMIT=$commit/" \
  -e "s/^OMARCHY_SHA256=.*/OMARCHY_SHA256=$sha256/" \
  "$env_file"
sed -i "s/quattro-[0-9][0-9.]*/quattro-$version/g" \
  files/scripts/install-omarchy-quattro.sh files/scripts/validate-omarchy-image.sh
echo "Pinned Omarchy $version at $commit"
