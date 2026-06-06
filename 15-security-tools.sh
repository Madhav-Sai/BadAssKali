#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log "Installing security tools..."

sudo apt install -y \
netexec \
bloodhound \
bloodhound-ce-python \
feroxbuster \
gobuster \
ffuf \
enum4linux-ng \
ldap-utils \
smbclient \
impacket-scripts \
seclists

log "Installing Certipy..."

pipx install certipy-ad || true

log "Installing RustScan..."

cargo install rustscan || true

log "Installing Kerbrute..."

cargo install kerbrute || true

echo
echo "=================================="
echo " Security Tools Installed"
echo "=================================="
echo