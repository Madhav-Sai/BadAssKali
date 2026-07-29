#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
chmod +x "$ROOT_DIR/badasskali"
ln -sfn "$ROOT_DIR/badasskali" "$BIN_DIR/badasskali"

echo "[+] Installed BadAssKali management CLI: $BIN_DIR/badasskali"
echo "    Run: badasskali help"
