#!/usr/bin/env bash

set -euo pipefail

EXPECTED_VENDOR="Fedora Copr - user lionheartp"
EXPECTED_REPO="copr:copr.fedorainfracloud.org:lionheartp:Hyprland"

fail() {
    echo "Hyprland stack validation failed: $*" >&2
    exit 1
}

recipe_requests() {
    local recipe_path="$1"
    local package_name="$2"

    awk -v package_name="${package_name}" '
        function indent_of(line, match_at) {
            match_at = match(line, /[^[:space:]]/)
            return match_at == 0 ? 9999 : match_at - 1
        }

        /^[[:space:]]*install:[[:space:]]*$/ {
            in_install = 1
            install_indent = indent_of($0)
            next
        }

        in_install {
            if ($0 ~ /^[[:space:]]*(#|$)/) {
                next
            }

            current_indent = indent_of($0)
            if (current_indent <= install_indent) {
                in_install = 0
                next
            }

            requested = "^[[:space:]]*-[[:space:]]+" package_name "([[:space:]#]|$)"
            if ($0 ~ requested) {
                found = 1
            }
        }

        END { exit found ? 0 : 1 }
    ' "${recipe_path}"
}

validate_recipe() {
    local recipe_path="$1"

    [[ -f "${recipe_path}" ]] || fail "recipe not found: ${recipe_path}"

    local requests_stable=0
    local requests_git=0
    local requests_stable_plugins=0
    local requests_git_plugins=0
    local requests_stable_waybar=0
    local requests_git_waybar=0

    recipe_requests "${recipe_path}" hyprland && requests_stable=1
    recipe_requests "${recipe_path}" hyprland-git && requests_git=1
    recipe_requests "${recipe_path}" hyprland-plugins && requests_stable_plugins=1
    recipe_requests "${recipe_path}" hyprland-plugins-git && requests_git_plugins=1
    recipe_requests "${recipe_path}" waybar && requests_stable_waybar=1
    recipe_requests "${recipe_path}" waybar-git && requests_git_waybar=1

    (( requests_stable + requests_git == 1 )) || \
        fail "recipe must request exactly one of hyprland and hyprland-git"

    if (( requests_git == 1 )); then
        (( requests_git_plugins == 1 && requests_stable_plugins == 0 )) || \
            fail "hyprland-git must be paired only with hyprland-plugins-git"
    else
        (( requests_stable_plugins == 1 && requests_git_plugins == 0 )) || \
            fail "hyprland must be paired only with hyprland-plugins"
    fi

    (( requests_stable_waybar == 0 && requests_git_waybar == 1 )) || \
        fail "recipe must replace stable waybar with waybar-git"

    grep -Eq '^base-image:[[:space:]]+ghcr\.io/wayblueorg/hyprland([[:space:]#]|$)' "${recipe_path}" || \
        fail "the default recipe must use the generic Wayblue Hyprland base"

    echo "Hyprland recipe request is coherent."
}

installed_metadata() {
    local package_name="$1"

    dnf5 --quiet repoquery --installed \
        --queryformat '%{name}|%{evr}|%{arch}|%{vendor}|%{sourcerpm}|%{from_repo}' \
        "${package_name}"
}

validate_package_source() {
    local package_name="$1"
    local vendor
    local from_repo

    rpm -q "${package_name}" >/dev/null 2>&1 || fail "required package is absent: ${package_name}"

    vendor="$(rpm -q --queryformat '%{VENDOR}' "${package_name}")"
    [[ "${vendor}" == "${EXPECTED_VENDOR}" ]] || \
        fail "${package_name} vendor is '${vendor}', expected '${EXPECTED_VENDOR}'"

    from_repo="$(dnf5 --quiet repoquery --installed --queryformat '%{from_repo}' "${package_name}")"
    [[ "${from_repo}" == "${EXPECTED_REPO}" ]] || \
        fail "${package_name} came from '${from_repo}', expected '${EXPECTED_REPO}'"

    [[ "$(rpm -q "${package_name}" | wc -l)" -eq 1 ]] || \
        fail "multiple installed versions of ${package_name}"
}

validate_exact_plugin_abi() {
    local compositor_abi
    local package_name
    local required_abi

    compositor_abi="$(rpm -q --queryformat '%{VERSION}' hyprland-git)"

    while IFS= read -r package_name; do
        [[ -n "${package_name}" ]] || continue
        required_abi="$(rpm -q --requires "${package_name}" | awk '/^hyprland-git = / { print $3; exit }')"
        [[ -n "${required_abi}" ]] || \
            fail "${package_name} does not declare an exact hyprland-git ABI requirement"
        [[ "${required_abi}" == "${compositor_abi}" ]] || \
            fail "${package_name} requires Hyprland ${required_abi}, installed ABI is ${compositor_abi}"
    done < <(rpm -qa --queryformat '%{NAME}\n' 'hyprland-plugins-git' 'hyprland-plugin-*-git' | sort -u)
}

validate_soname_providers() {
    local requirement
    local providers
    local provider_count
    local library_pattern
    local owner_count

    while IFS= read -r requirement; do
        [[ -n "${requirement}" ]] || continue
        providers="$(rpm -q --whatprovides "${requirement}" 2>/dev/null || true)"
        provider_count="$(sed '/^[[:space:]]*$/d' <<<"${providers}" | wc -l)"
        [[ "${provider_count}" -eq 1 ]] || \
            fail "${requirement} has ${provider_count} installed providers: ${providers:-none}"
    done < <(rpm -q --requires hyprland-git | grep -E '^lib(aquamarine|hypr[^[:space:]]*)\.so\..*\(64bit\)$')

    for library_pattern in libaquamarine.so. libhyprcursor.so. libhyprgraphics.so. \
        libhyprlang.so. libhyprutils.so. libhyprwire.so.; do
        owner_count="$({
            find /usr/lib64 -maxdepth 1 -type l -name "${library_pattern}[0-9]*" -print0
        } | xargs -0 -r rpm -qf --queryformat '%{NAME}\n' 2>/dev/null | sort -u | wc -l)"
        [[ "${owner_count}" -le 1 ]] || \
            fail "${library_pattern} has files owned by multiple incompatible packages"
    done
}

validate_dynamic_links() {
    local elf_path
    local unresolved

    while IFS= read -r elf_path; do
        [[ -n "${elf_path}" ]] || continue
        unresolved="$(ldd "${elf_path}" 2>/dev/null | grep 'not found' || true)"
        [[ -z "${unresolved}" ]] || fail "unresolved libraries for ${elf_path}: ${unresolved}"
    done < <(
        printf '%s\n' /usr/bin/Hyprland
        find /usr/lib64/hyprland -maxdepth 1 -type f -name '*.so' -print 2>/dev/null | sort
    )
}

validate_installed() {
    local manifest_path="${HYPRLAND_MANIFEST_PATH:-/usr/share/obsidian-blue/hyprland-package-manifest.txt}"
    local package_name
    local -a required_packages=(
        hyprland-git
        hyprland-plugins-git
        hyprland-plugin-borders-plus-plus-git
        hyprland-plugin-csgo-vulkan-fix-git
        hyprland-plugin-hyprbars-git
        hyprland-plugin-hyprfocus-git
        aquamarine
        hyprcursor
        hyprgraphics
        hyprlang
        hyprutils
        hyprwire
        hyprtoolkit
        xdg-desktop-portal-hyprland
        hyprpaper
        hyprlock
        hypridle
        uwsm
        hyprland-guiutils
        hyprland-qt-support
        hyprpicker
        hyprshot
        hyprpolkitagent
        hyprsunset
        hyprland-contrib
        waybar-git
    )

    rpm -q hyprland >/dev/null 2>&1 && fail "stable hyprland is installed beside the selected git line"
    rpm -q hyprland-plugins >/dev/null 2>&1 && fail "stable hyprland-plugins is installed beside the selected git line"
    rpm -q hyprland-qtutils >/dev/null 2>&1 && fail "retired hyprland-qtutils survived replacement"
    rpm -q waybar >/dev/null 2>&1 && fail "stable waybar is installed beside waybar-git"

    for package_name in "${required_packages[@]}"; do
        validate_package_source "${package_name}"
    done

    [[ -x /usr/bin/uwsm-app ]] || \
        fail "uwsm package does not provide the required /usr/bin/uwsm-app launcher"

    dnf5 check --dependencies --duplicates >/dev/null || \
        fail "DNF reports dependency, conflict, or duplicate-package problems"

    validate_exact_plugin_abi
    validate_soname_providers
    validate_dynamic_links

    install -d "$(dirname "${manifest_path}")"
    {
        echo '# name|evr|arch|vendor|source_rpm|from_repo'
        for package_name in "${required_packages[@]}"; do
            installed_metadata "${package_name}"
            echo
        done
    } >"${manifest_path}"

    echo "Hyprland installed stack is coherent; manifest: ${manifest_path}"
}

case "${1:---installed}" in
    --recipe)
        [[ $# -eq 2 ]] || fail "usage: $0 --recipe PATH"
        validate_recipe "$2"
        ;;
    --installed)
        [[ $# -eq 1 || $# -eq 0 ]] || fail "usage: $0 --installed"
        validate_installed
        ;;
    *)
        fail "usage: $0 [--installed | --recipe PATH]"
        ;;
esac
