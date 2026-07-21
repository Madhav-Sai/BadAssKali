#!/usr/bin/env bash

set -Eeuo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

cleanup() {
    if [[ -n "${work_dir:-}" && -d "${work_dir:-}" ]]; then
        rm -rf "$work_dir"
    fi
}
trap cleanup EXIT

echo
echo "=================================="
echo "     Ghostty Installation"
echo "=================================="
echo

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    fail "Do not run this module as root. Run it as your normal user."
fi

if [[ ! -r /etc/os-release ]]; then
    fail "Unable to detect the Linux distribution: /etc/os-release is missing."
fi

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="${ID,,}"
OS_LIKE="${ID_LIKE:-}"
OS_LIKE="${OS_LIKE,,}"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) zig_arch="x86_64-linux" ;;
    aarch64|arm64) zig_arch="aarch64-linux" ;;
    *) fail "Unsupported architecture: $ARCH. Supported: x86_64 and aarch64/arm64." ;;
esac

info "Detected system: ${PRETTY_NAME:-$OS_ID} ($ARCH)"

install_debian_dependencies() {
    log "Installing Ghostty build dependencies with APT..."
    sudo apt-get update

    local packages=(
        build-essential
        ca-certificates
        curl
        gettext
        git
        jq
        libadwaita-1-dev
        libgtk-4-dev
        libgtk4-layer-shell-dev
        pkg-config
        xz-utils
    )

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

install_arch_dependencies() {
    log "Installing Ghostty build dependencies with pacman..."

    local packages=(
        base-devel
        ca-certificates
        curl
        gettext
        git
        gtk4
        gtk4-layer-shell
        jq
        libadwaita
        pkgconf
        xz
    )

    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

case "$OS_ID" in
    kali|parrot|debian|ubuntu|linuxmint|pop)
        command -v apt-get >/dev/null 2>&1 || fail "APT was expected but apt-get was not found."
        install_debian_dependencies
        ;;
    arch|endeavouros|manjaro|garuda)
        command -v pacman >/dev/null 2>&1 || fail "pacman was expected but was not found."
        install_arch_dependencies
        ;;
    *)
        if [[ " $OS_LIKE " == *" debian "* ]]; then
            command -v apt-get >/dev/null 2>&1 || fail "Debian-based system detected, but apt-get was not found."
            install_debian_dependencies
        elif [[ " $OS_LIKE " == *" arch "* ]]; then
            command -v pacman >/dev/null 2>&1 || fail "Arch-based system detected, but pacman was not found."
            install_arch_dependencies
        else
            fail "Unsupported distribution: ${PRETTY_NAME:-$OS_ID}. Supported families: Debian/Ubuntu/Kali/Parrot and Arch Linux."
        fi
        ;;
esac

for required_command in curl git jq tar awk sort; do
    command -v "$required_command" >/dev/null 2>&1 || fail "Required command is missing after dependency installation: $required_command"
done

work_dir="$(mktemp -d -t badasskali-ghostty.XXXXXX)"

log "Finding a downloadable stable Ghostty release..."

candidate_versions=()

# Primary discovery source: Ghostty's official release-notes page.
# This avoids depending on the GitHub Releases API, which may return 404.
if release_notes_html="$(curl -fsSL --retry 4 --retry-all-errors \
    --connect-timeout 20 https://ghostty.org/docs/install/release-notes 2>/dev/null)"; then

    while IFS= read -r detected_version; do
        [[ -n "$detected_version" ]] && candidate_versions+=("$detected_version")
    done < <(
        printf '%s' "$release_notes_html" \
            | grep -oE '/docs/install/release-notes/[0-9]+-[0-9]+-[0-9]+' \
            | sed -E 's#.*/([0-9]+)-([0-9]+)-([0-9]+)#\1.\2.\3#' \
            | sort -Vru
    )
else
    warn "Unable to read Ghostty's official release-notes page."
fi

# Secondary discovery source: stable tags from the read-only Git mirror.
if [[ ${#candidate_versions[@]} -eq 0 ]]; then
    warn "Falling back to Ghostty Git tags."

    while IFS= read -r detected_version; do
        [[ -n "$detected_version" ]] && candidate_versions+=("$detected_version")
    done < <(
        git ls-remote --tags --refs https://github.com/ghostty-org/ghostty.git 2>/dev/null \
            | awk -F/ '{print $3}' \
            | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
            | sed 's/^v//' \
            | sort -Vru
    )
fi

# Known stable fallback releases.
candidate_versions+=("1.3.1" "1.3.0" "1.2.3")

mapfile -t candidate_versions < <(
    printf '%s\n' "${candidate_versions[@]}" \
        | awk 'NF && !seen[$0]++' \
        | sort -Vr
)

version=""
source_archive=""

for candidate in "${candidate_versions[@]}"; do
    candidate_url="https://release.files.ghostty.org/${candidate}/ghostty-${candidate}.tar.gz"
    candidate_archive="$work_dir/ghostty-${candidate}.tar.gz"

    info "Trying Ghostty ${candidate}: $candidate_url"

    if curl -fL --retry 4 --retry-all-errors --connect-timeout 20 \
        "$candidate_url" -o "$candidate_archive"; then

        # Reject HTML directory indexes and error pages even when they return HTTP 200.
        if tar -tzf "$candidate_archive" >/dev/null 2>&1; then
            version="$candidate"
            source_archive="$candidate_archive"
            break
        fi

        warn "Ghostty ${candidate} download was not a valid source archive."
        rm -f "$candidate_archive"
    else
        warn "Ghostty ${candidate} was unavailable."
        rm -f "$candidate_archive"
    fi
done

[[ -n "$version" && -s "$source_archive" ]] \
    || fail "Unable to download a valid Ghostty source tarball."

log "Selected Ghostty release: v${version}"

log "Extracting Ghostty source..."
tar -xzf "$source_archive" -C "$work_dir"

repo_dir="$work_dir/ghostty-${version}"
[[ -d "$repo_dir" ]] || fail "Expected source directory not found: $repo_dir"

zig_version="$(awk -F'"' '/minimum_zig_version/ {print $2; exit}' "$repo_dir/build.zig.zon")"
[[ -n "$zig_version" ]] || fail "Unable to determine Ghostty's required Zig version."

zig_root="$HOME/.local/opt"
zig_dir="$zig_root/zig-$zig_version"
zig_bin="$zig_dir/zig"

if [[ ! -x "$zig_bin" ]]; then
    log "Installing Zig $zig_version for the Ghostty build..."
    mkdir -p "$zig_root"

    zig_archive="$work_dir/zig.tar.xz"
    zig_url="https://ziglang.org/download/$zig_version/zig-$zig_arch-$zig_version.tar.xz"

    curl --fail --location --retry 3 --retry-delay 2 \
        "$zig_url" -o "$zig_archive"

    tar -xJf "$zig_archive" -C "$work_dir"

    extracted_zig="$work_dir/zig-$zig_arch-$zig_version"
    [[ -x "$extracted_zig/zig" ]] || fail "Downloaded Zig archive did not contain the expected binary."

    rm -rf "$zig_dir"
    mv "$extracted_zig" "$zig_dir"
else
    info "Reusing Zig $zig_version from $zig_dir"
fi

log "Building Ghostty v${version} with Zig $zig_version..."
cd "$repo_dir"
"$zig_bin" build -Doptimize=ReleaseFast

log "Installing Ghostty into /usr/local..."
sudo env PATH="$(dirname "$zig_bin"):$PATH" \
    "$zig_bin" build install \
    -Doptimize=ReleaseFast \
    --prefix /usr/local

# Ensure a predictable command lookup even if sudo uses a restricted PATH.
if [[ ! -x /usr/local/bin/ghostty ]]; then
    fail "Ghostty build completed, but /usr/local/bin/ghostty was not installed."
fi

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/ghostty.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Ghostty
GenericName=Terminal Emulator
Comment=Fast, native, feature-rich terminal emulator
Exec=/usr/local/bin/ghostty
TryExec=/usr/local/bin/ghostty
Icon=com.mitchellh.ghostty
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=true
DESKTOP

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

hash -r 2>/dev/null || true

if command -v ghostty >/dev/null 2>&1; then
    installed_ghostty="$(command -v ghostty)"
elif [[ -x /usr/local/bin/ghostty ]]; then
    installed_ghostty="/usr/local/bin/ghostty"
else
    fail "Ghostty installation verification failed."
fi

log "Ghostty installed successfully."
"$installed_ghostty" --version || true
info "Binary: $installed_ghostty"
info "Distribution support: Kali, Parrot OS, Debian, Ubuntu, Arch Linux, and common derivatives."
