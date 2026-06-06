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
echo " Rust Installation"
echo "=================================="
echo

if [[ -f "$HOME/.cargo/env" ]]; then

# shellcheck disable=SC1091
    source "$HOME/.cargo/env"

    if command -v rustc >/dev/null 2>&1; then

        warn "Rust already installed."

        rustc --version

        exit 0

    fi

fi

log "Installing Rust..."

curl --proto '=https' \
     --tlsv1.2 \
     -sSf \
     https://sh.rustup.rs | sh -s -- -y

# shellcheck disable=SC1091
source "$HOME/.cargo/env"

export PATH="$HOME/.cargo/bin:$PATH"

# Persist Cargo PATH for future shells
if ! grep -q '.cargo/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
fi

log "Updating Rust..."

rustup update

rustup default stable

echo
echo "Rust Information"
echo "================"
echo

which rustc
rustc --version

echo

which cargo
cargo --version

echo

log "Installing useful Rust components..."

rustup component add \
    rustfmt \
    clippy

echo
echo "=================================="
echo " Rust Installed"
echo "=================================="
echo