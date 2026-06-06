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
echo " TheFuck Installation"
echo "=================================="
echo

if command -v thefuck >/dev/null 2>&1; then

    warn "TheFuck already installed."

    thefuck --version || true

    exit 0

fi

log "Installing dependencies..."

sudo apt update

sudo apt install -y \
    python3 \
    python3-venv \
    python3-pip

VENV_DIR="$HOME/.venvs/thefuck"

mkdir -p "$HOME/.venvs"

log "Creating virtual environment..."

python3 -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

pip install --upgrade pip

# pkg_resources compatibility
pip install "setuptools<81"

log "Installing TheFuck..."

pip install thefuck

deactivate

if [[ ! -f "$VENV_DIR/bin/thefuck" ]]; then

    fail "TheFuck installation failed."

fi

if ! grep -q ".venvs/thefuck/bin" "$HOME/.zshrc" 2>/dev/null; then

cat >> "$HOME/.zshrc" << 'EOF'

# TheFuck
export PATH="$HOME/.venvs/thefuck/bin:$PATH"
eval "$(thefuck --alias)"

EOF

fi

export PATH="$HOME/.venvs/thefuck/bin:$PATH"

echo
echo "=================================="
echo " TheFuck Installed"
echo "=================================="
echo

thefuck --version