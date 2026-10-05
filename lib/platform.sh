#!/usr/bin/env bash

# Shared distribution and package-manager helpers.

detect_platform() {
    local os_release="${BADASSKALI_OS_RELEASE:-/etc/os-release}"
    [[ -r "$os_release" ]] || return 1
    # shellcheck disable=SC1090
    source "$os_release"

    BAK_OS_ID="$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')"
    BAK_OS_LIKE="${ID_LIKE:-}"
    BAK_OS_LIKE="$(printf '%s' "$BAK_OS_LIKE" | tr '[:upper:]' '[:lower:]')"
    BAK_OS_NAME="${PRETTY_NAME:-$BAK_OS_ID}"
    BAK_OS_VERSION="${VERSION_ID:-unknown}"
    BAK_ARCH="$(uname -m)"

    case "$BAK_OS_ID" in
        kali | parrot | debian | ubuntu | linuxmint | pop)
            BAK_PACKAGE_FAMILY="debian"
            ;;
        arch | endeavouros | manjaro | garuda)
            BAK_PACKAGE_FAMILY="arch"
            ;;
        fedora | rhel | centos | rocky | almalinux)
            BAK_PACKAGE_FAMILY="fedora"
            ;;
        opensuse* | sles)
            BAK_PACKAGE_FAMILY="suse"
            ;;
        *)
            if [[ " $BAK_OS_LIKE " == *" debian "* ]]; then
                BAK_PACKAGE_FAMILY="debian"
            elif [[ " $BAK_OS_LIKE " == *" arch "* ]]; then
                BAK_PACKAGE_FAMILY="arch"
            elif [[ " $BAK_OS_LIKE " == *" fedora "* || " $BAK_OS_LIKE " == *" rhel "* ]]; then
                BAK_PACKAGE_FAMILY="fedora"
            elif [[ " $BAK_OS_LIKE " == *" suse "* ]]; then
                BAK_PACKAGE_FAMILY="suse"
            else
                BAK_PACKAGE_FAMILY="unknown"
            fi
            ;;
    esac

    case "$BAK_OS_ID" in
        kali) BAK_SECURITY_DISTRO="kali" ;;
        parrot) BAK_SECURITY_DISTRO="parrot" ;;
        *) BAK_SECURITY_DISTRO="generic" ;;
    esac

    export BAK_OS_ID BAK_OS_LIKE BAK_OS_NAME BAK_OS_VERSION BAK_ARCH
    export BAK_PACKAGE_FAMILY BAK_SECURITY_DISTRO
}

platform_summary() {
    printf '%s (id=%s version=%s family=%s arch=%s)\n' \
        "$BAK_OS_NAME" "$BAK_OS_ID" "$BAK_OS_VERSION" \
        "$BAK_PACKAGE_FAMILY" "$BAK_ARCH"
}

platform_diagnostics() {
    echo "Platform: $(platform_summary)"
    echo "Package manager: $(package_manager 2>/dev/null || echo unavailable)"

    case "$BAK_PACKAGE_FAMILY" in
        debian)
            if command -v dpkg >/dev/null 2>&1; then
                local audit
                audit="$(dpkg --audit 2>&1 || true)"
                if [[ -n "$audit" ]]; then
                    echo "DPKG audit:"
                    printf '%s\n' "$audit"
                else
                    echo "DPKG audit: clean"
                fi
            fi
            if command -v apt-get >/dev/null 2>&1; then
                if apt-get check >/dev/null 2>&1; then
                    echo "APT dependency check: clean"
                else
                    echo "APT dependency check: failed (try: sudo apt --fix-broken install)"
                fi
            fi
            if [[ "$BAK_OS_ID" == "parrot" ]]; then
                command -v parrot-upgrade >/dev/null 2>&1 ||
                    echo "Parrot notice: parrot-upgrade is missing; verify the official Parrot repositories."
                if pkg_available parrot-core; then
                    echo "Parrot repositories: detected"
                else
                    echo "Parrot repositories: parrot-core is unavailable"
                fi
            fi
            ;;
    esac
}

package_manager() {
    case "${BAK_PACKAGE_FAMILY:-unknown}" in
        debian) printf 'apt-get\n' ;;
        arch) printf 'pacman\n' ;;
        fedora) printf 'dnf\n' ;;
        suse) printf 'zypper\n' ;;
        *) return 1 ;;
    esac
}

# have_cmd NAME: like `command -v`, but also finds tools installed in the
# per-user bin dirs that are often missing from PATH while the installer runs.
have_cmd() {
    local name="$1" dir
    command -v "$name" >/dev/null 2>&1 && return 0
    for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.atuin/bin" \
        "$HOME/.pdtm/go/bin" "$HOME/go/bin" /usr/local/bin; do
        [[ -x "$dir/$name" ]] && return 0
    done
    return 1
}

# Refresh package metadata at most once per BADASSKALI_UPDATE_TTL seconds
# (default 6h) instead of once per module. Set BADASSKALI_FORCE_UPDATE=true to override.
pkg_update() {
    if [[ "${BADASSKALI_OFFLINE:-false}" == "true" ]]; then
        return 0
    fi
    local stamp="${XDG_STATE_HOME:-$HOME/.local/state}/badasskali/pkg-update.stamp"
    local ttl="${BADASSKALI_UPDATE_TTL:-21600}" now age
    now="$(date +%s)"
    if [[ "${BADASSKALI_FORCE_UPDATE:-false}" != "true" && -r "$stamp" ]]; then
        age=$((now - $(cat "$stamp" 2>/dev/null || echo 0)))
        if ((age >= 0 && age < ttl)); then
            echo "[*] Package lists refreshed $((age / 60)) min ago; skipping update."
            return 0
        fi
    fi
    _pkg_update_now || return 1
    mkdir -p "$(dirname "$stamp")"
    printf '%s\n' "$now" >"$stamp"
}

_pkg_update_now() {
    case "$BAK_PACKAGE_FAMILY" in
        debian)
            if ! sudo apt-get update; then
                echo "APT metadata refresh failed on $(platform_summary)." >&2
                echo "Check network access and files under /etc/apt/sources.list.d/." >&2
                return 1
            fi
            ;;
        arch) sudo pacman -Sy --noconfirm ;;
        fedora) sudo dnf makecache -y ;;
        suse) sudo zypper --non-interactive refresh ;;
        *) return 1 ;;
    esac
}

pkg_install() {
    [[ $# -gt 0 ]] || return 0

    # Skip packages that are already installed (groups like @dev-tools pass through).
    if [[ "${BADASSKALI_DOWNLOAD_ONLY:-false}" != "true" &&
        "${BADASSKALI_OFFLINE:-false}" != "true" ]]; then
        local wanted=() item
        for item in "$@"; do
            if [[ "$item" == @* ]] || ! pkg_installed "$item"; then
                wanted+=("$item")
            fi
        done
        if [[ ${#wanted[@]} -eq 0 ]]; then
            echo "[*] Already installed, skipping: $*"
            return 0
        fi
        set -- "${wanted[@]}"
    fi
    local cache_dir="${BADASSKALI_CACHE_DIR:-$HOME/.cache/badasskali/packages}"
    mkdir -p "$cache_dir"

    if [[ "${BADASSKALI_DOWNLOAD_ONLY:-false}" == "true" ]]; then
        case "$BAK_PACKAGE_FAMILY" in
            debian)
                mkdir -p "$cache_dir/partial"
                sudo apt-get install -y --download-only \
                    -o "Dir::Cache::archives=$cache_dir" "$@"
                ;;
            arch) sudo pacman -Sw --needed --noconfirm --cachedir "$cache_dir" "$@" ;;
            fedora) sudo dnf install -y --downloadonly --downloaddir "$cache_dir" "$@" ;;
            suse) sudo zypper --non-interactive --pkg-cache-dir "$cache_dir" install --download-only "$@" ;;
        esac
        return
    fi

    if [[ "${BADASSKALI_OFFLINE:-false}" == "true" ]]; then
        case "$BAK_PACKAGE_FAMILY" in
            debian)
                mkdir -p "$cache_dir/partial"
                sudo apt-get install -y --no-download \
                    -o "Dir::Cache::archives=$cache_dir" "$@"
                ;;
            arch)
                local cached_packages=() package cached_file
                for package in "$@"; do
                    cached_file="$(find "$cache_dir" -maxdepth 1 -type f \
                        -name "${package}-*.pkg.tar.*" ! -name '*.sig' | sort -V | tail -n 1)"
                    [[ -n "$cached_file" ]] || {
                        echo "Missing cached Arch package: $package" >&2
                        return 1
                    }
                    cached_packages+=("$cached_file")
                done
                sudo pacman -U --needed --noconfirm "${cached_packages[@]}"
                ;;
            fedora) sudo dnf install -y --cacheonly "$@" ;;
            suse) sudo zypper --non-interactive --cache-only install "$@" ;;
        esac
        return
    fi

    case "$BAK_PACKAGE_FAMILY" in
        debian)
            if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -- "$@"; then
                echo "Package installation failed: $*" >&2
                echo "Run 'badasskali doctor' for repository and dpkg diagnostics." >&2
                return 1
            fi
            ;;
        arch) sudo pacman -S --needed --noconfirm "$@" ;;
        fedora) sudo dnf install -y "$@" ;;
        suse) sudo zypper --non-interactive install "$@" ;;
        *) return 1 ;;
    esac
}

pkg_remove() {
    [[ $# -gt 0 ]] || return 0
    case "$BAK_PACKAGE_FAMILY" in
        debian) sudo env DEBIAN_FRONTEND=noninteractive apt-get remove -y -- "$@" ;;
        arch) sudo pacman -Rns --noconfirm "$@" ;;
        fedora) sudo dnf remove -y "$@" ;;
        suse) sudo zypper --non-interactive remove "$@" ;;
        *) return 1 ;;
    esac
}

pkg_available() {
    local package="$1"
    case "$BAK_PACKAGE_FAMILY" in
        debian) apt-cache show "$package" >/dev/null 2>&1 ;;
        arch) pacman -Si "$package" >/dev/null 2>&1 ;;
        fedora) dnf info "$package" >/dev/null 2>&1 ;;
        suse) zypper --non-interactive info "$package" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

pkg_installed() {
    local package="$1"
    case "$BAK_PACKAGE_FAMILY" in
        debian) dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -Fq 'install ok installed' ;;
        arch) pacman -Q "$package" >/dev/null 2>&1 ;;
        fedora | suse) rpm -q "$package" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}
