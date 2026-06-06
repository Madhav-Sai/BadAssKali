#!/usr/bin/env bash

set -euo pipefail

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

error() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

if ! command -v cargo >/dev/null 2>&1; then
    error "Cargo not found. Run 06-rust.sh first."
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

TOOLS=(
    git-delta
    bottom
    dust
    hyperfine
    procs
)

for tool in "${TOOLS[@]}"
do

    if command -v "$tool" >/dev/null 2>&1; then

        warn "$tool already installed."

        continue

    fi

    log "Installing $tool..."

    cargo install \
        --locked \
        "$tool" || warn "$tool installation failed"

done

echo
echo "=================================="
echo " Cargo Tools Installed"
echo "=================================="
echo

for tool in "${TOOLS[@]}"
do
    command -v "$tool" >/dev/null 2>&1 && \
        echo "[OK] $tool"
done