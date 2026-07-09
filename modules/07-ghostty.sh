#!/usr/bin/env bash

set -Eeuo pipefail

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
echo "     Ghostty Installation"
echo "=================================="
echo

if command -v ghostty >/dev/null 2>&1; then
    warn "Ghostty is already installed."
    ghostty --version || true
    exit 0
fi

log "Installing dependencies..."

sudo apt update

sudo apt install -y \
    build-essential \
    pkg-config \
    git \
    wget \
    curl \
    jq \
    xz-utils \
    ca-certificates \
    libgtk-4-dev \
    libadwaita-1-dev \
    libgtk4-layer-shell-dev \
    libglib2.0-dev \
    libwayland-dev \
    wayland-protocols

################################################################################
# Install Latest Stable Zig Automatically
################################################################################

install_zig() {

    log "Installing latest stable Zig..."

    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            ZIG_ARCH="x86_64-linux"
            ;;
        aarch64|arm64)
            ZIG_ARCH="aarch64-linux"
            ;;
        *)
            fail "Unsupported architecture: $ARCH"
            ;;
    esac

    TMP_ZIG=$(mktemp -d)

    cd "$TMP_ZIG"

    log "Fetching latest Zig version..."

    ZIG_VERSION=$(curl -fsSL https://ziglang.org/download/index.json \
        | jq -r '.master.version')

    [[ -n "$ZIG_VERSION" ]] || fail "Unable to determine latest Zig version."

    log "Latest Zig: $ZIG_VERSION"

    ZIG_URL=$(curl -fsSL https://ziglang.org/download/index.json \
        | jq -r ".master.\"${ZIG_ARCH}\".tarball")

    [[ -n "$ZIG_URL" && "$ZIG_URL" != "null" ]] || fail "Unable to fetch Zig download URL."

    wget -q "$ZIG_URL" -O zig.tar.xz

    tar -xf zig.tar.xz

    ZIG_DIR=$(find . -maxdepth 1 -type d -name "zig-*")

    sudo rm -rf /opt/zig

    sudo mv "$ZIG_DIR" /opt/zig

    sudo ln -sf /opt/zig/zig /usr/local/bin/zig

    cd -

    rm -rf "$TMP_ZIG"

    log "Installed Zig $(zig version)"

}

if command -v zig >/dev/null 2>&1; then

    log "Using Zig $(zig version)"

else

    warn "Zig not found."

    install_zig

fi

################################################################################
# Clone Ghostty
################################################################################

TMP_DIR=$(mktemp -d)

cd "$TMP_DIR"

log "Cloning Ghostty..."

git clone --depth=1 https://github.com/ghostty-org/ghostty.git

cd ghostty

################################################################################
# Build Ghostty
################################################################################

log "Building Ghostty..."

zig build -Doptimize=ReleaseFast

################################################################################
# Install Ghostty
################################################################################

log "Installing Ghostty..."

sudo zig build install \
    -Doptimize=ReleaseFast \
    --prefix /usr/local

################################################################################
# Desktop Entry
################################################################################

mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/ghostty.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Ghostty
Exec=ghostty
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

################################################################################
# Cleanup
################################################################################

cd

rm -rf "$TMP_DIR"

################################################################################
# Verify
################################################################################

if ! command -v ghostty >/dev/null 2>&1; then
    fail "Ghostty installation failed."
fi

echo
echo "=================================="
echo "     Ghostty Installed"
echo "=================================="
echo

ghostty --version

echo
log "Installation completed successfully!"
