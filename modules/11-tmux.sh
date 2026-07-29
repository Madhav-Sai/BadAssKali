#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

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
echo " tmux Setup"
echo "=================================="
echo

if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then

    warn "TPM already installed."

    exit 0

fi

detect_platform || { echo "Unable to detect a supported package manager." >&2; exit 1; }
pkg_update
pkg_install tmux

mkdir -p "$HOME/.tmux/plugins"

git clone https://github.com/tmux-plugins/tpm \
    "$HOME/.tmux/plugins/tpm"

echo
echo "=================================="
echo " tmux Installed"
echo "=================================="
echo

echo "Run inside tmux:"
echo
echo "  Prefix + I"
echo
