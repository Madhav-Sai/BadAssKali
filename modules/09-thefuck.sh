#!/usr/bin/env bash

set -Eeuo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

echo
echo "=================================="
echo "       TheFuck Installer"
echo "=================================="
echo

if command -v thefuck >/dev/null 2>&1; then
    warn "TheFuck is already installed."
    thefuck --version || true
    exit 0
fi

log "Installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl

export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv >/dev/null 2>&1; then
    log "Installing uv to manage an isolated Python runtime..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null 2>&1 || fail "uv installation failed."

log "Installing TheFuck with Python 3.11..."
uv tool install --python 3.11 --upgrade thefuck
command -v thefuck >/dev/null 2>&1 || fail "TheFuck installation failed."

case "${SHELL##*/}" in
    zsh) rc_file="$HOME/.zshrc" ;;
    bash) rc_file="$HOME/.bashrc" ;;
    *) rc_file="$HOME/.profile" ;;
esac

touch "$rc_file"
if ! grep -q 'THEFUCK_INIT' "$rc_file"; then
    cat >> "$rc_file" <<'EOF'

# THEFUCK_INIT
export PATH="$HOME/.local/bin:$PATH"
eval "$(thefuck --alias)"
EOF
fi

log "TheFuck $(thefuck --version) installed successfully."
echo "Reload with: source \"$rc_file\""
