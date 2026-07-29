#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
install -m 0755 "$ROOT_DIR/configs/bin/bak-engage" "$BIN_DIR/bak-engage"

echo "[+] Installed the engagement workspace manager."
echo "    Start with: bak-engage new client-assessment --scope example.com"
