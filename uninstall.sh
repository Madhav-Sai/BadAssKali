#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo
echo "=================================="
echo " Kali Beast Uninstaller"
echo "=================================="
echo

read -rp "Continue? [y/N] " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    exit 0
fi

log "Removing Oh My Zsh..."

rm -rf ~/.oh-my-zsh

log "Removing Powerlevel10k..."

rm -rf ~/.p10k.zsh

log "Removing tmux plugins..."

rm -rf ~/.tmux

log "Removing Atuin..."

rm -rf ~/.atuin

log "Removing TheFuck..."

rm -rf ~/.venvs/thefuck

log "Removing Cargo tools..."

rm -rf ~/.cargo
rm -rf ~/.rustup

log "Removing Ghostty config..."

rm -rf ~/.config/ghostty

log "Removing Kali Beast config..."

rm -rf ~/.config/kali-beast

log "Removing fonts..."

rm -rf ~/.local/share/fonts/JetBrainsMono

fc-cache -fv >/dev/null 2>&1 || true

log "Removing desktop entry..."

rm -f ~/.local/share/applications/ghostty.desktop

log "Removing generated files..."

rm -f ~/.zshrc

echo
echo "=================================="
echo " Uninstall Complete"
echo "=================================="
echo