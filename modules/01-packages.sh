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
echo " Installing Base Packages"
echo "=================================="
echo

sudo apt update

PACKAGES=(
    git
    curl
    wget
    unzip
    zip
    tar
    gzip
    bzip2
    xz-utils
    build-essential
    pkg-config
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release
    jq
    yq
    tree
    htop
    btop
    fastfetch
    fzf
    ripgrep
    fd-find
    bat
    eza
    zoxide
    ranger
    neovim
    tmux
    python3
    python3-pip
    python3-venv
    pipx
    net-tools
    dnsutils
    nmap
    smbclient
    ldap-utils
    seclists
)

log "Installing packages..."

sudo apt install -y "${PACKAGES[@]}"

if ! command -v git >/dev/null 2>&1; then
    fail "Package installation failed."
fi

log "Base packages installed successfully."

echo