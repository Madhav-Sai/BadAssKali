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

if ! command -v cargo >/dev/null 2>&1; then
    echo "Cargo not installed."
    exit 1
fi

TOOLS=(
git-delta
bottom
dust
hyperfine
procs
du-dust
)

for tool in "${TOOLS[@]}"
do
    log "Installing $tool"

    cargo install \
    --locked \
    "$tool" || warn "$tool failed"
done

echo
echo "=================================="
echo " Cargo Tools Installed"
echo "=================================="
echo