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

for required_command in fc-list fc-cache wget unzip; do
    command -v "$required_command" >/dev/null 2>&1 ||
        fail "$required_command is required. Re-run module 01 (base packages) first."
done

# Nerd Fonts 3.x registers the family as "JetBrainsMono NF" / "JetBrainsMono Nerd Font",
# so match both, and also look for the font files directly in case the cache is stale.
font_installed() {
    fc-list 2>/dev/null | grep -Eqi 'JetBrainsMono ?(Nerd Font|NF)' && return 0
    find "$FONT_DIR" /usr/share/fonts /usr/local/share/fonts -iname 'JetBrainsMono*Nerd*' \
        -print -quit 2>/dev/null | grep -q .
}

if font_installed; then

    warn "JetBrainsMono Nerd Font already installed."

    exit 0

fi

mkdir -p "$FONT_DIR"

# Keep the 128MB archive so a re-run never downloads it again.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/badasskali"
mkdir -p "$CACHE_DIR"
FONT_ZIP="$CACHE_DIR/JetBrainsMono-NerdFont.zip"

if [[ -s "$FONT_ZIP" ]] && unzip -tq "$FONT_ZIP" >/dev/null 2>&1; then
    log "Reusing cached font archive: $FONT_ZIP"
else
    log "Downloading JetBrainsMono Nerd Font (about 128 MB)..."
    rm -f -- "$FONT_ZIP"
    wget -q --show-progress -O "$FONT_ZIP.part" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -tq "$FONT_ZIP.part" >/dev/null 2>&1 || fail "Downloaded font archive is corrupt."
    mv -f "$FONT_ZIP.part" "$FONT_ZIP"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TMP_DIR"' EXIT

log "Extracting fonts..."

unzip -oq "$FONT_ZIP" '*.ttf' -d "$TMP_DIR"

log "Installing fonts..."

cp "$TMP_DIR"/*.ttf "$FONT_DIR"

fc-cache -f "$FONT_DIR" >/dev/null 2>&1

echo
echo "=================================="
echo " Fonts Installed"
echo "=================================="
echo

echo "Recommended Font:"
echo
echo "JetBrainsMono Nerd Font"
echo
