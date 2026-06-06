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

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    error "Oh My Zsh not installed. Run 03-ohmyzsh.sh first."
fi

CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

mkdir -p "$CUSTOM_DIR/plugins"
mkdir -p "$CUSTOM_DIR/themes"

install_plugin() {

    local repo="$1"
    local target="$2"

    if [[ -d "$target" ]]; then
        warn "$(basename "$target") already installed. Skipping."
        return
    fi

    git clone --depth=1 "$repo" "$target"
}

log "Installing Powerlevel10k..."

install_plugin \
"https://github.com/romkatv/powerlevel10k.git" \
"$CUSTOM_DIR/themes/powerlevel10k"

log "Installing zsh-autosuggestions..."

install_plugin \
"https://github.com/zsh-users/zsh-autosuggestions" \
"$CUSTOM_DIR/plugins/zsh-autosuggestions"

log "Installing zsh-syntax-highlighting..."

install_plugin \
"https://github.com/zsh-users/zsh-syntax-highlighting" \
"$CUSTOM_DIR/plugins/zsh-syntax-highlighting"

log "Installing zsh-completions..."

install_plugin \
"https://github.com/zsh-users/zsh-completions" \
"$CUSTOM_DIR/plugins/zsh-completions"

log "Installing fzf-tab..."

install_plugin \
"https://github.com/Aloxaf/fzf-tab" \
"$CUSTOM_DIR/plugins/fzf-tab"

echo
echo "=================================="
echo " Powerlevel10k Stack Installed"
echo "=================================="
echo

echo "Installed:"
echo "  ✓ Powerlevel10k"
echo "  ✓ zsh-autosuggestions"
echo "  ✓ zsh-syntax-highlighting"
echo "  ✓ zsh-completions"
echo "  ✓ fzf-tab"
echo