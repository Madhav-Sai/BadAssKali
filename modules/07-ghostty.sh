#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

ZIG_VERSION="0.15.2"

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

ARCH=$(uname -m)

case "$ARCH" in

    x86_64)
        ZIG_ARCH="x86_64"
        ;;

    aarch64|arm64)
        ZIG_ARCH="aarch64"
        ;;

    *)
        error "Unsupported architecture: $ARCH"
        ;;
esac

if command -v ghostty >/dev/null 2>&1; then

    warn "Ghostty already installed."

    ghostty --version || true

    exit 0

fi

log "Installing Zig..."

cd /tmp

rm -rf zig-* || true

wget \
https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz

tar -xf zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz

sudo rm -rf /opt/zig

sudo mv \
zig-linux-${ZIG_ARCH}-${ZIG_VERSION} \
/opt/zig

sudo ln -sf /opt/zig/zig /usr/local/bin/zig

zig version

log "Cloning Ghostty..."

rm -rf /tmp/ghostty || true

git clone https://github.com/ghostty-org/ghostty.git

cd ghostty

log "Building Ghostty..."

zig build -Doptimize=ReleaseFast

log "Installing Ghostty..."

sudo zig build install \
-Doptimize=ReleaseFast

if ! command -v ghostty >/dev/null 2>&1; then
    error "Ghostty installation failed."
fi

ghostty --version

log "Creating desktop entry..."

mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/ghostty.desktop << EOF
[Desktop Entry]
Type=Application
Name=Ghostty
Exec=ghostty
Terminal=false
Categories=System;TerminalEmulator;
EOF

echo
echo "=================================="
echo " Ghostty Installed"
echo "=================================="
echo

ghostty --version