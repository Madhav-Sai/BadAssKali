#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

FONT_NAME="JetBrainsMono"
FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"

if [[ -d "$FONT_DIR" ]]; then
    warn "JetBrainsMono Nerd Font already installed."
    fc-cache -fv >/dev/null 2>&1 || true
    exit 0
fi

mkdir -p "$FONT_DIR"

TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

log "Downloading JetBrainsMono Nerd Font..."

wget -q \
-O "$TMP_DIR/JetBrainsMono.zip" \
https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

log "Extracting font..."

unzip -qq \
"$TMP_DIR/JetBrainsMono.zip" \
-d "$FONT_DIR"

log "Refreshing font cache..."

fc-cache -fv >/dev/null

if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    log "JetBrainsMono Nerd Font installed successfully."
else
    error "Font installation failed."
fi

echo
echo "=================================="
echo " Fonts Installed"
echo "=================================="
echo
echo "Font:"
echo "  ✓ JetBrainsMono Nerd Font"
echo