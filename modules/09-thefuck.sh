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

THEFUCK_DIR="$HOME/.venvs/thefuck"

if [[ -x "$THEFUCK_DIR/bin/thefuck" ]]; then

    warn "TheFuck already installed."

    "$THEFUCK_DIR/bin/thefuck" --version

    exit 0

fi

log "Creating virtual environment..."

python3 -m venv "$THEFUCK_DIR"

source "$THEFUCK_DIR/bin/activate"

log "Updating pip..."

pip install --upgrade pip

log "Installing compatible setuptools..."

pip install "setuptools<81"

log "Cloning TheFuck..."

rm -rf /tmp/thefuck || true

git clone \
https://github.com/nvbn/thefuck.git \
/tmp/thefuck

log "Applying Python 3.13 patch..."

sed -i \
's/from distutils.spawn import find_executable/from shutil import which as find_executable/' \
/tmp/thefuck/thefuck/system/unix.py

cd /tmp/thefuck

log "Installing TheFuck..."

pip install --no-build-isolation .

deactivate

if [[ ! -x "$THEFUCK_DIR/bin/thefuck" ]]; then
    error "TheFuck installation failed."
fi

if ! grep -q ".venvs/thefuck/bin" ~/.zshrc 2>/dev/null; then

cat >> ~/.zshrc << 'EOF'

# TheFuck
export PATH="$HOME/.venvs/thefuck/bin:$PATH"

if [ -x "$HOME/.venvs/thefuck/bin/thefuck" ]; then
    eval "$($HOME/.venvs/thefuck/bin/thefuck --alias)"
fi

EOF

fi

echo
echo "=================================="
echo " TheFuck Installed"
echo "=================================="
echo

"$THEFUCK_DIR/bin/thefuck" --version