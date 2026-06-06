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

log "Checking Oh My Zsh installation..."

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "Oh My Zsh already installed."
    exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    error "Zsh is not installed. Run 02-zsh.sh first."
fi

log "Installing Oh My Zsh..."

export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

sh -c "$(
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
)"

log "Creating custom directories..."

mkdir -p \
"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

mkdir -p \
"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"

log "Verifying installation..."

[[ -d "$HOME/.oh-my-zsh" ]] || error "Installation failed."

log "Oh My Zsh installed successfully."

echo
echo "=================================="
echo " Oh My Zsh Ready"
echo "=================================="
echo