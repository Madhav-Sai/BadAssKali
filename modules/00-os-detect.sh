#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

if [[ ! -f /etc/os-release ]]; then
    fail "Unable to determine operating system."
fi

source /etc/os-release

ARCH=$(uname -m)

echo
echo "=================================="
echo " Operating System Detection"
echo "=================================="
echo

log "Detected OS: $PRETTY_NAME"
log "Detected Architecture: $ARCH"

case "$ID" in

    kali|debian|ubuntu)
        log "Supported distribution."
        ;;

    *)
        fail "Unsupported distribution: $ID"
        ;;

esac

case "$ARCH" in

    x86_64|aarch64|arm64)
        log "Supported architecture."
        ;;

    *)
        fail "Unsupported architecture: $ARCH"
        ;;

esac

echo