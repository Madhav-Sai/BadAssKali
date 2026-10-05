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

detect_platform || { echo "Unable to detect a supported package manager." >&2; exit 1; }
if command -v tmux >/dev/null 2>&1; then
    warn "tmux already installed."
else
    pkg_update
    pkg_install tmux
fi

echo
echo "=================================="
echo " tmux Installed (stock settings, prefix Ctrl+b)"
echo "=================================="
echo
