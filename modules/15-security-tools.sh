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

fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

echo
echo "=================================="
echo " Security Tools Installation"
echo "=================================="
echo

log "Updating package lists..."

sudo apt update

APT_TOOLS=(
    netexec
    ffuf
    feroxbuster
    gobuster
    smbclient
    ldap-utils
    enum4linux-ng
    seclists
    evil-winrm
    responder
    bloodhound
    bloodhound-ce-python
    impacket-scripts
)

for tool in "${APT_TOOLS[@]}"
do

    log "Installing $tool..."

    sudo apt install -y "$tool" || warn "$tool installation failed"

done

echo

if command -v pipx >/dev/null 2>&1; then

    log "Installing Certipy..."

    pipx install certipy-ad --force || warn "Certipy installation failed"

fi

echo

if command -v cargo >/dev/null 2>&1; then

    mkdir -p "$HOME/cargo-build"

    export TMPDIR="$HOME/cargo-build"
    export CARGO_TARGET_DIR="$HOME/cargo-build/target"
    export CARGO_BUILD_JOBS=1

    log "Installing RustScan..."

    cargo install \
        --locked \
        rustscan || warn "RustScan installation failed"

fi

echo
echo "=================================="
echo " Security Tools Installed"
echo "=================================="
echo

TOOLS=(
    netexec
    certipy
    ffuf
    feroxbuster
    gobuster
    rustscan
)

for tool in "${TOOLS[@]}"
do

    if command -v "$tool" >/dev/null 2>&1; then

        echo "[OK] $tool"

    else

        echo "[MISSING] $tool"

    fi

done

echo