#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
install -m 0755 "$ROOT_DIR/configs/bin/bak-recon" "$BIN_DIR/bak-recon"

echo "[+] Installed the scope-aware recon workflow."
echo "    Read its guardrails with: bak-recon help"
