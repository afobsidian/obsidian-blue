#!/usr/bin/env bash

set -euo pipefail

readonly LAZYGIT_VERSION="0.61.1"
readonly NWG_DISPLAYS_VERSION="0.3.28"
readonly WALLUST_VERSION="3.5.2"
readonly BLUETUI_VERSION="0.4.2"
readonly EZA_VERSION="0.20.18"
readonly IMPALA_VERSION="0.3.0"
readonly TARGET_BIN_DIR="/usr/local/bin"
readonly WORKDIR="$(mktemp -d)"

cleanup() {
    rm -rf "${WORKDIR}"
}

download() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${url}" -o "${output}"
        return
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO "${output}" "${url}"
        return
    fi

    echo "Neither curl nor wget is available for downloading ${url}" >&2
    exit 1
}

install_lazygit() {
    local arch
    local tarball="${WORKDIR}/lazygit.tar.gz"
    local extract_dir="${WORKDIR}/lazygit"

    case "$(uname -m)" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            echo "Unsupported architecture for lazygit: $(uname -m)" >&2
            exit 1
            ;;
    esac

    mkdir -p "${extract_dir}"
    download \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${arch}.tar.gz" \
        "${tarball}"
    tar -xzf "${tarball}" -C "${extract_dir}" lazygit
    install -Dm755 "${extract_dir}/lazygit" "${TARGET_BIN_DIR}/lazygit"
}

install_nwg_displays() {
    local tarball="${WORKDIR}/nwg-displays.tar.gz"
    local src_dir="${WORKDIR}/nwg-displays"

    mkdir -p "${src_dir}"
    download \
        "https://github.com/nwg-piotr/nwg-displays/archive/refs/tags/v${NWG_DISPLAYS_VERSION}.tar.gz" \
        "${tarball}"
    tar -xzf "${tarball}" -C "${src_dir}" --strip-components=1

    (
        cd "${src_dir}"
        python3 -m build --wheel --no-isolation
        python3 -m installer dist/*.whl
        install -Dm644 "nwg-displays.desktop" "/usr/share/applications/nwg-displays.desktop"
        install -Dm644 "nwg-displays.svg" "/usr/share/pixmaps/nwg-displays.svg"
        install -Dm644 "LICENSE" "/usr/share/licenses/nwg-displays/LICENSE"
        install -Dm644 "README.md" "/usr/share/doc/nwg-displays/README.md"
    )
}

install_wallust() {
    local tarball="${WORKDIR}/wallust.tar.gz"
    local src_dir="${WORKDIR}/wallust"

    mkdir -p "${src_dir}"
    download \
        "https://codeberg.org/explosion-mental/wallust/archive/${WALLUST_VERSION}.tar.gz" \
        "${tarball}"
    tar -xzf "${tarball}" -C "${src_dir}" --strip-components=1

    (
        cd "${src_dir}"
        export CARGO_HOME="${WORKDIR}/cargo-home"
        export CARGO_TARGET_DIR="${WORKDIR}/cargo-target"
        cargo install --path . --locked --root /usr/local
    )
}

install_cargo_bin() {
    local name="$1"
    local version="$2"

    export CARGO_HOME="${WORKDIR}/cargo-home"
    export CARGO_TARGET_DIR="${WORKDIR}/cargo-target"
    cargo install "${name}" --version "${version}" --locked --root /usr/local
}

trap cleanup EXIT

install_lazygit
install_nwg_displays
install_wallust
install_cargo_bin bluetui "${BLUETUI_VERSION}"
install_cargo_bin eza "${EZA_VERSION}"
install_cargo_bin impala "${IMPALA_VERSION}"