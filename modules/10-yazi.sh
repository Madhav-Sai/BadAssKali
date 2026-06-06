#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.cargo/env" 2>/dev/null || true

export PATH="$HOME/.cargo/bin:$PATH"

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
echo " Yazi Installation"
echo "=================================="
echo

if command -v yazi >/dev/null 2>&1; then

    warn "Yazi already installed."

    yazi --version

    exit 0

fi

if ! command -v cargo >/dev/null 2>&1; then

    fail "Cargo not found. Run 06-rust.sh first."

fi

echo
echo "Rust Information"
echo "================"

which rustc
rustc --version

echo

which cargo
cargo --version

echo

mkdir -p "$HOME/cargo-build"

export TMPDIR="$HOME/cargo-build"
export CARGO_TARGET_DIR="$HOME/cargo-build/target"
export CARGO_BUILD_JOBS=1

log "Installing Yazi build helper..."

cargo install \
    --locked \
    --force \
    yazi-build

log "Installing Yazi..."

if cargo install \
    --locked \
    yazi-fm
then

    cargo install \
        --locked \
        yazi-cli

    log "Yazi installed successfully."

else

    warn "Yazi build failed."

    warn "Installing ranger fallback..."

    sudo apt update

    sudo apt install -y ranger

fi

echo
echo "=================================="
echo " Yazi Installation Complete"
echo "=================================="
echo

if command -v yazi >/dev/null 2>&1; then

    yazi --version

elif command -v ranger >/dev/null 2>&1; then

    echo "Ranger installed as fallback."

else

    warn "Neither Yazi nor Ranger available."

fi

echo