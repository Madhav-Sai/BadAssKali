#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.cargo/env" 2>/dev/null || true
export PATH="$HOME/.cargo/bin:$PATH"

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

log "Installing security packages..."

sudo apt update

sudo apt install -y \
    feroxbuster \
    ffuf \
    gobuster \
    smbclient \
    ldap-utils \
    seclists \
    bloodhound \
    bloodhound-ce-python \
    enum4linux-ng \
    impacket-scripts \
    netexec

log "Installing Certipy..."

pipx install certipy-ad --force || true

if command -v cargo >/dev/null 2>&1; then

    log "Installing RustScan..."

    cargo install \
        --locked \
        rustscan || true

    log "Installing Kerbrute..."

    cargo install \
        --locked \
        kerbrute || true

fi

echo
echo "=================================="
echo " Security Tools Installed"
echo "=================================="
echo

TOOLS=(
    netexec
    certipy
    feroxbuster
    ffuf
    gobuster
)

for tool in "${TOOLS[@]}"
do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[OK] $tool"
    fi
done