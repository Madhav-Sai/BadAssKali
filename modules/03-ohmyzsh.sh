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
    warn "Oh My Zsh already installed; checking plugins."
else
    log "Installing Oh My Zsh..."
    RUNZSH=no \
        CHSH=no \
        KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_repo() {
    local name="$1" url="$2" destination="$3"
    if [[ -d "$destination/.git" ]]; then
        log "Updating $name..."
        git -C "$destination" pull --ff-only || warn "$name update was skipped."
    elif [[ -e "$destination" ]]; then
        warn "$name destination exists but is not a Git checkout: $destination"
    else
        log "Installing $name..."
        git clone --depth=1 "$url" "$destination"
    fi
}

install_repo "Powerlevel10k" https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
install_repo "zsh-autosuggestions" https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_repo "zsh-syntax-highlighting" https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
install_repo "zsh-completions" https://github.com/zsh-users/zsh-completions \
    "$ZSH_CUSTOM/plugins/zsh-completions"
install_repo "fzf-tab" https://github.com/Aloxaf/fzf-tab \
    "$ZSH_CUSTOM/plugins/fzf-tab"

echo
echo "=================================="
echo " Oh My Zsh Installed"
echo "=================================="
echo
