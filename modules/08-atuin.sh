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
echo " Atuin Installation"
echo "=================================="
echo

if command -v atuin >/dev/null 2>&1; then

    warn "Atuin already installed."

    atuin --version

    exit 0

fi

log "Installing Atuin..."

curl --proto '=https' \
     --tlsv1.2 \
     -LsSf https://setup.atuin.sh | sh -s -- --yes

export PATH="$HOME/.atuin/bin:$PATH"

if ! command -v atuin >/dev/null 2>&1; then

    fail "Atuin installation failed."

fi

echo
echo "=================================="
echo " Atuin Installed"
echo "=================================="
echo

atuin --version

echo
echo "Optional:"
echo
echo "  atuin import auto"
echo "  atuin register"
echo