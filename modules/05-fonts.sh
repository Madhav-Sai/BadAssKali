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

fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

echo
echo "=================================="
echo " Nerd Fonts Installation"
echo "=================================="
echo

FONT_DIR="$HOME/.local/share/fonts"

if fc-list | grep -qi "JetBrainsMono Nerd Font"; then

    warn "JetBrainsMono Nerd Font already installed."

    exit 0

fi

mkdir -p "$FONT_DIR"

TMP_DIR=$(mktemp -d)

cd "$TMP_DIR"

log "Downloading JetBrainsMono Nerd Font..."

wget -O JetBrainsMono.zip \
https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

log "Extracting fonts..."

unzip -o JetBrainsMono.zip -d JetBrainsMono

log "Installing fonts..."

cp JetBrainsMono/*.ttf "$FONT_DIR"

fc-cache -fv >/dev/null 2>&1

rm -rf "$TMP_DIR"

echo
echo "=================================="
echo " Fonts Installed"
echo "=================================="
echo

echo "Recommended Font:"
echo
echo "JetBrainsMono Nerd Font"
echo