#!/usr/bin/env bash

set -Eeuo pipefail

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
echo "     TheFuck Installer"
echo "=================================="
echo

# Detect package manager
if command -v apt >/dev/null 2>&1; then
    PKG_INSTALL="sudo apt update && sudo apt install -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG_INSTALL="sudo dnf install -y"
elif command -v pacman >/dev/null 2>&1; then
    PKG_INSTALL="sudo pacman -Sy --noconfirm"
elif command -v brew >/dev/null 2>&1; then
    PKG_INSTALL="brew install"
else
    fail "Unsupported package manager."
fi

# Install dependencies
log "Installing dependencies..."

if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y \
        git \
        python3 \
        python3-venv \
        python3-pip
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y \
        git \
        python3 \
        python3-pip
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm \
        git \
        python \
        python-pip
elif command -v brew >/dev/null 2>&1; then
    brew install git python
fi

PYTHON=$(command -v python3 || command -v python)

[[ -n "$PYTHON" ]] || fail "Python not found."

PY_VER=$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

log "Python version: $PY_VER"

VENV_DIR="$HOME/.venvs/thefuck"

if [[ -d "$VENV_DIR" ]]; then
    warn "Removing existing virtual environment..."
    rm -rf "$VENV_DIR"
fi

mkdir -p "$(dirname "$VENV_DIR")"

log "Creating virtual environment..."

"$PYTHON" -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

log "Upgrading pip..."

python -m pip install --upgrade pip setuptools wheel

# Ubuntu/Kali Python 3.12 compatibility
if [[ "$PY_VER" =~ ^3\.12|^3\.13 ]]; then
    warn "Python >=3.12 detected."

    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y python3-zombie-imp || true
    fi
fi

log "Installing latest TheFuck from GitHub..."

pip install --no-cache-dir \
    git+https://github.com/nvbn/thefuck.git

deactivate

THEFUCK_BIN="$VENV_DIR/bin/thefuck"

[[ -x "$THEFUCK_BIN" ]] || fail "Installation failed."

# Determine shell rc file
case "${SHELL##*/}" in
    zsh)
        RC="$HOME/.zshrc"
        ;;
    bash)
        RC="$HOME/.bashrc"
        ;;
    *)
        RC="$HOME/.profile"
        ;;
esac

if ! grep -q "THEFUCK_VENV" "$RC" 2>/dev/null; then

cat >> "$RC" <<EOF

# THEFUCK_VENV
export PATH="$VENV_DIR/bin:\$PATH"
eval "\$(thefuck --alias)"
EOF

fi

export PATH="$VENV_DIR/bin:$PATH"

echo
echo "=================================="
echo " Installation Complete"
echo "=================================="
echo

echo "Version:"
thefuck --version || true

echo
echo "Reload your shell:"
echo
echo "    source \"$RC\""
echo
echo "or simply open a new terminal."
echo
echo "Usage:"
echo
echo "    sl"
echo "    fuck"
echo
