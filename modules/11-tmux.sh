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
command -v tmux >/dev/null 2>&1 || { pkg_update; pkg_install tmux; }

mkdir -p "$HOME/.tmux/plugins"

if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    warn "TPM already installed."
else
    git clone --depth 1 https://github.com/tmux-plugins/tpm \
        "$HOME/.tmux/plugins/tpm"
fi

# Install plugins now so nobody has to remember the prefix + I step.
if [[ -f "$HOME/.tmux.conf" ]]; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "Plugin install failed; run prefix + I inside tmux."
fi

echo
echo "=================================="
echo " tmux Installed"
echo "=================================="
echo
echo "Prefix is Ctrl+a. Plugins: Ctrl+a then Shift+i (if any are missing)."
echo
