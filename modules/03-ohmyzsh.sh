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
echo " Oh My Zsh Setup"
echo "=================================="
echo

if [[ -d "$HOME/.oh-my-zsh" ]]; then

    warn "Oh My Zsh already installed."

    exit 0

fi

log "Installing Oh My Zsh..."

RUNZSH=no \
CHSH=no \
KEEP_ZSHRC=yes \
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log "Installing Powerlevel10k..."

git clone --depth=1 \
https://github.com/romkatv/powerlevel10k.git \
"$ZSH_CUSTOM/themes/powerlevel10k"

log "Installing zsh-autosuggestions..."

git clone --depth=1 \
https://github.com/zsh-users/zsh-autosuggestions \
"$ZSH_CUSTOM/plugins/zsh-autosuggestions"

log "Installing zsh-syntax-highlighting..."

git clone --depth=1 \
https://github.com/zsh-users/zsh-syntax-highlighting \
"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

log "Installing zsh-completions..."

git clone --depth=1 \
https://github.com/zsh-users/zsh-completions \
"$ZSH_CUSTOM/plugins/zsh-completions"

log "Installing fzf-tab..."

git clone --depth=1 \
https://github.com/Aloxaf/fzf-tab \
"$ZSH_CUSTOM/plugins/fzf-tab"

echo
echo "=================================="
echo " Oh My Zsh Installed"
echo "=================================="
echo