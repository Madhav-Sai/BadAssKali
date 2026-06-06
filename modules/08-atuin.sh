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

if command -v atuin >/dev/null 2>&1; then

    warn "Atuin already installed."

    atuin --version

    exit 0

fi

log "Installing Atuin..."

curl --proto '=https' \
     --tlsv1.2 \
     -LsSf \
     https://setup.atuin.sh | sh

if [[ ! -x "$HOME/.atuin/bin/atuin" ]]; then

    error "Atuin installation failed."

fi

if ! grep -q "atuin init zsh" ~/.zshrc 2>/dev/null; then

cat >> ~/.zshrc << 'EOF'

# Atuin
export PATH="$HOME/.atuin/bin:$PATH"

eval "$(atuin init zsh)"

EOF

fi

log "Importing existing history..."

"$HOME/.atuin/bin/atuin" import auto || true

echo
echo "=================================="
echo " Atuin Installed"
echo "=================================="
echo

"$HOME/.atuin/bin/atuin" --version