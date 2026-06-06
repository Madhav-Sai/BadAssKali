#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

error() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

log "Detecting operating system..."

if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect operating system."
fi

source /etc/os-release

DISTRO="$ID"
DISTRO_VERSION="$VERSION_ID"

case "$DISTRO" in
    kali|debian|ubuntu)
        ;;
    *)
        error "Unsupported distribution: $DISTRO"
        ;;
esac

log "Detecting architecture..."

ARCH_RAW=$(uname -m)

case "$ARCH_RAW" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        error "Unsupported architecture: $ARCH_RAW"
        ;;
esac

export DISTRO
export DISTRO_VERSION
export ARCH

log "Distro      : $DISTRO"
log "Version     : $DISTRO_VERSION"
log "Architecture: $ARCH"