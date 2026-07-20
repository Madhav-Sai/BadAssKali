#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

if [[ ! -r /etc/os-release ]]; then
    fail "Unable to determine operating system."
fi

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="${ID,,}"
OS_LIKE="${ID_LIKE:-}"
OS_LIKE="${OS_LIKE,,}"
ARCH="$(uname -m)"

echo
echo "=================================="
echo " Operating System Detection"
echo "=================================="
echo

log "Detected OS: ${PRETTY_NAME:-$OS_ID}"
log "Detected Architecture: $ARCH"

case "$ARCH" in
    x86_64|aarch64|arm64)
        log "Supported architecture."
        ;;
    *)
        fail "Unsupported architecture: $ARCH"
        ;;
esac

case "$OS_ID" in
    kali)
        DISTRO_FAMILY="debian"
        log "Supported distribution: Kali Linux."
        ;;
    parrot)
        DISTRO_FAMILY="debian"
        log "Supported distribution: Parrot OS."
        ;;
    debian|ubuntu|linuxmint|pop)
        DISTRO_FAMILY="debian"
        log "Supported Debian/Ubuntu-family distribution."
        ;;
    arch|endeavouros|manjaro|garuda)
        DISTRO_FAMILY="arch"
        log "Supported Arch-family distribution."
        ;;
    *)
        if [[ " $OS_LIKE " == *" debian "* ]]; then
            DISTRO_FAMILY="debian"
            log "Supported Debian-family derivative."
        elif [[ " $OS_LIKE " == *" arch "* ]]; then
            DISTRO_FAMILY="arch"
            log "Supported Arch-family derivative."
        else
            fail "Unsupported distribution: ${PRETTY_NAME:-$OS_ID}"
        fi
        ;;
esac

info "Package family: $DISTRO_FAMILY"
echo
