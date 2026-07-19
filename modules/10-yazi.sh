#!/usr/bin/env bash

set -Eeuo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

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

case "$(uname -m)" in
    x86_64) asset_pattern='yazi-x86_64-unknown-linux-gnu\.deb$' ;;
    aarch64|arm64) asset_pattern='yazi-aarch64-unknown-linux-gnu\.deb$' ;;
    *) fail "Unsupported architecture: $(uname -m)" ;;
esac

log "Installing Yazi preview and archive helpers..."
sudo apt update
sudo apt install -y ffmpeg file imagemagick jq p7zip-full poppler-utils ripgrep \
    fd-find unzip wl-clipboard

log "Fetching the latest Yazi release..."
release_json=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest)
deb_url=$(jq -r --arg pattern "$asset_pattern" \
    '.assets[] | select(.name | test($pattern)) | .browser_download_url' <<<"$release_json" | head -n1)
[[ -n "$deb_url" && "$deb_url" != "null" ]] || fail "No Yazi package is available for this architecture."

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
curl -fL "$deb_url" -o "$work_dir/yazi.deb"

log "Installing Yazi..."
sudo apt install -y "$work_dir/yazi.deb"

command -v yazi >/dev/null 2>&1 || fail "Yazi installation failed."
log "Yazi $(yazi --version) installed successfully."
