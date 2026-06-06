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

for cmd in git wget tar grep sudo; do
    command -v "$cmd" >/dev/null 2>&1 || error "$cmd not installed"
done

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

    read -rp "Rebuild Ghostty? [y/N] " REBUILD

    if [[ ! "$REBUILD" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

log "Cloning Ghostty repository..."

rm -rf /tmp/ghostty

git clone --depth=1 https://github.com/ghostty-org/ghostty.git /tmp/ghostty

cd /tmp/ghostty

ZIG_VERSION=$(grep minimum_zig_version build.zig.zon | cut -d'"' -f2)

[[ -z "$ZIG_VERSION" ]] && error "Unable to determine required Zig version."

log "Ghostty requires Zig ${ZIG_VERSION}"

cd /tmp

rm -rf zig-* || true

log "Downloading Zig..."

wget \
"https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz"

log "Extracting Zig..."

tar -xf "zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz"

log "Installing Zig..."

sudo rm -rf /opt/zig

sudo mv \
"zig-${ZIG_ARCH}-linux-${ZIG_VERSION}" \
/opt/zig

sudo ln -sf /opt/zig/zig /usr/local/bin/zig

log "Zig version:"

zig version

cd /tmp/ghostty

log "Building Ghostty..."

zig build -Doptimize=ReleaseFast

log "Installing Ghostty..."

sudo zig build install \
-Doptimize=ReleaseFast \
--prefix /usr/local

if ! command -v ghostty >/dev/null 2>&1; then
    error "Ghostty installation failed."
fi

log "Creating desktop entry..."

mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/ghostty.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Ghostty
Exec=ghostty
Terminal=false
Categories=System;TerminalEmulator;
EOF

update-desktop-database ~/.local/share/applications 2>/dev/null || true

echo
echo "=================================="
echo " Ghostty Installed"
echo "=================================="
echo

ghostty --version