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
echo " ZSH Setup"
echo "=================================="
echo

if ! command -v zsh >/dev/null 2>&1; then

    log "Installing ZSH..."

    sudo apt update

    sudo apt install -y zsh

fi

log "ZSH version:"

zsh --version

CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" == "zsh" ]]; then

    warn "ZSH already configured."

    exit 0

fi

log "Setting ZSH as default shell..."

chsh -s "$(which zsh)"

echo
echo "=================================="
echo " ZSH Installed"
echo "=================================="
echo

echo "Logout and login again for shell changes to take effect."
echo