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
echo " Ghostty Installation"
echo "=================================="
echo

if command -v ghostty >/dev/null 2>&1; then

    warn "Ghostty already installed."

    ghostty --version || true

    exit 0

fi

log "Installing Ghostty dependencies..."

sudo apt update

sudo apt install -y \
    build-essential \
    pkg-config \
    git \
    wget \
    libgtk-4-dev \
    libadwaita-1-dev \
    libgtk4-layer-shell-dev \
    libglib2.0-dev \
    libwayland-dev \
    wayland-protocols

if ! command -v zig >/dev/null 2>&1; then

    warn "Zig not found."

    warn "Install Zig manually if Ghostty build fails."

fi

TMP_DIR=$(mktemp -d)

cd "$TMP_DIR"

log "Cloning Ghostty..."

git clone --depth=1 https://github.com/ghostty-org/ghostty.git

cd ghostty

log "Building Ghostty..."

if zig build -Doptimize=ReleaseFast; then

    log "Installing Ghostty..."

    sudo zig build install \
        -Doptimize=ReleaseFast \
        --prefix /usr/local

else

    fail "Ghostty build failed."

fi

if ! command -v ghostty >/dev/null 2>&1; then

    fail "Ghostty installation failed."

fi

mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/ghostty.desktop << EOF
[Desktop Entry]
Type=Application
Name=Ghostty
Exec=ghostty
Terminal=false
Categories=System;TerminalEmulator;
EOF

update-desktop-database ~/.local/share/applications 2>/dev/null || true

rm -rf "$TMP_DIR"

echo
echo "=================================="
echo " Ghostty Installed"
echo "=================================="
echo

ghostty --version