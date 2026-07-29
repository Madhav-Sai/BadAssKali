#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

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

detect_platform || fail "Unable to detect a supported package manager."

echo
echo "=================================="
echo " ZSH Setup"
echo "=================================="
echo

if ! command -v zsh >/dev/null 2>&1; then

    log "Installing ZSH..."

    pkg_update
    pkg_install zsh

fi

log "ZSH version:"

zsh --version

CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" == "zsh" ]]; then

    warn "ZSH already configured."

    exit 0

fi

log "Setting ZSH as default shell..."

if ! chsh -s "$(command -v zsh)"; then
    warn "Could not change the login shell automatically."
    warn "Run this after installation: chsh -s $(command -v zsh)"
fi

echo
echo "=================================="
echo " ZSH Installed"
echo "=================================="
echo

echo "Logout and login again for shell changes to take effect."
echo
