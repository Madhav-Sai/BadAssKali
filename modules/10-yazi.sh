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
}

if command -v yazi >/dev/null 2>&1; then

    warn "Yazi already installed."

    yazi --version

    exit 0

fi

if ! command -v cargo >/dev/null 2>&1; then

    error "Cargo not found. Run 06-rust.sh first."

    exit 1

fi

log "Preparing build directories..."

mkdir -p "$HOME/cargo-build"

export TMPDIR="$HOME/cargo-build"
export CARGO_TARGET_DIR="$HOME/cargo-build/target"

export CARGO_BUILD_JOBS=1

log "Installing yazi-build..."

cargo install \
--locked \
--force \
yazi-build

log "Installing Yazi..."

if cargo install \
--locked \
--force \
yazi-fm \
yazi-cli
then

    log "Yazi installed successfully."

else

    warn "Yazi build failed."

    warn "Falling back to ranger."

    sudo apt install -y ranger

fi

echo
echo "=================================="
echo " Yazi Installation Complete"
echo "=================================="
echo

if command -v yazi >/dev/null 2>&1; then

    yazi --version

else

    echo "Using ranger fallback."

fi