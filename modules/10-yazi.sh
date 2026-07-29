#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

echo
echo "=================================="
echo "       Yazi Installation"
echo "=================================="
echo

if command -v yazi >/dev/null 2>&1; then
    warn "Yazi is already installed."
    yazi --version
    exit 0
fi

detect_platform || fail "Unable to detect a supported package manager."
pkg_update

case "$BAK_PACKAGE_FAMILY" in
    arch)
        pkg_install yazi ffmpeg imagemagick jq p7zip poppler ripgrep fd unzip wl-clipboard
        ;;
    fedora | suse)
        if pkg_available yazi; then
            pkg_install yazi
        else
            fail "Yazi is not available in the configured repositories for $BAK_OS_NAME."
        fi
        ;;
    debian)
        case "$BAK_ARCH" in
            x86_64) asset_pattern='yazi-x86_64-unknown-linux-gnu\.deb$' ;;
            aarch64 | arm64) asset_pattern='yazi-aarch64-unknown-linux-gnu\.deb$' ;;
            *) fail "Unsupported architecture: $BAK_ARCH" ;;
        esac

        helpers=(ffmpeg file imagemagick jq p7zip-full poppler-utils ripgrep fd-find unzip wl-clipboard)
        available_helpers=()
        for helper in "${helpers[@]}"; do
            if pkg_available "$helper"; then
                available_helpers+=("$helper")
            else
                warn "Skipping unavailable preview helper: $helper"
            fi
        done
        pkg_install "${available_helpers[@]}"

        log "Fetching the latest Yazi release metadata..."
        release_json="$(curl -fsSL --retry 3 https://api.github.com/repos/sxyazi/yazi/releases/latest)"
        deb_url="$(jq -r --arg pattern "$asset_pattern" \
            '.assets[] | select(.name | test($pattern)) | .browser_download_url' \
            <<<"$release_json" | head -n1)"
        [[ -n "$deb_url" && "$deb_url" != "null" ]] ||
            fail "No Yazi package is available for this architecture."

        work_dir="$(mktemp -d -t badasskali-yazi.XXXXXX)"
        trap 'rm -rf -- "$work_dir"' EXIT
        curl -fL --retry 3 "$deb_url" -o "$work_dir/yazi.deb"
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$work_dir/yazi.deb"
        ;;
esac

command -v yazi >/dev/null 2>&1 || fail "Yazi installation failed."
log "Yazi $(yazi --version) installed successfully."
