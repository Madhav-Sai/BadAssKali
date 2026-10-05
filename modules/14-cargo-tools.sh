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
echo " Cargo Tools Installation"
echo "=================================="
echo

if ! command -v cargo >/dev/null 2>&1; then
    fail "Cargo not found. Run 06-rust.sh first."
fi

mkdir -p "$HOME/cargo-build"

export TMPDIR="$HOME/cargo-build"
export CARGO_TARGET_DIR="$HOME/cargo-build/target"
export CARGO_BUILD_JOBS=1

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# crate:binary
TOOLS=(
    git-delta:delta
    bottom:btm
    dust:dust
    hyperfine:hyperfine
    procs:procs
)

for entry in "${TOOLS[@]}"
do
    tool="${entry%%:*}"
    binary="${entry##*:}"

    if command -v "$binary" >/dev/null 2>&1; then

        warn "$tool already installed ($binary)."

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

echo "Installed Tools:"
echo

command -v delta >/dev/null 2>&1 && echo "  ✓ delta"
command -v btm >/dev/null 2>&1 && echo "  ✓ bottom"
command -v dust >/dev/null 2>&1 && echo "  ✓ dust"
command -v hyperfine >/dev/null 2>&1 && echo "  ✓ hyperfine"
command -v procs >/dev/null 2>&1 && echo "  ✓ procs"

echo
