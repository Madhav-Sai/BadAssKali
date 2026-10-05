#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

# shellcheck disable=SC1091
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

detect_platform || fail "Unable to detect a supported package manager."
log "Updating package lists..."
pkg_update

case "$BAK_PACKAGE_FAMILY" in
    debian)
        SECURITY_TOOLS=(netexec ffuf feroxbuster gobuster smbclient ldap-utils enum4linux-ng seclists evil-winrm responder bloodhound bloodhound-ce-python impacket-scripts)
        ;;
    arch)
        SECURITY_TOOLS=(ffuf feroxbuster gobuster smbclient openldap seclists impacket)
        ;;
    fedora)
        SECURITY_TOOLS=(ffuf gobuster samba-client openldap-clients)
        ;;
    suse)
        SECURITY_TOOLS=(gobuster samba-client openldap2-client)
        ;;
esac

for tool in "${SECURITY_TOOLS[@]}"; do

    if pkg_installed "$tool"; then
        log "$tool already installed."
    elif pkg_available "$tool"; then
        log "Installing $tool..."
        pkg_install "$tool" || warn "$tool installation failed"
    else
        warn "$tool is unavailable in the configured repositories"
    fi

done

echo

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if have_cmd certipy || have_cmd certipy-ad; then

    log "Certipy already installed."

elif command -v pipx >/dev/null 2>&1; then

    log "Installing Certipy..."

    pipx install certipy-ad || warn "Certipy installation failed"

fi

echo

if have_cmd rustscan; then

    log "RustScan already installed."

elif command -v cargo >/dev/null 2>&1; then

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
