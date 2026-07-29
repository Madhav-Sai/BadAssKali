#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

detect_platform || {
    echo "[-] Unable to determine operating system." >&2
    exit 1
}

echo
echo "=================================="
echo " Operating System Detection"
echo "=================================="
echo
echo "[+] OS: $BAK_OS_NAME"
echo "[+] Architecture: $BAK_ARCH"
echo "[+] Package family: $BAK_PACKAGE_FAMILY"

case "$BAK_ARCH" in
    x86_64 | aarch64 | arm64) ;;
    *)
        echo "[-] Unsupported architecture: $BAK_ARCH" >&2
        exit 1
        ;;
esac

[[ "$BAK_PACKAGE_FAMILY" != "unknown" ]] ||
    {
        echo "[-] Unsupported distribution: $BAK_OS_NAME" >&2
        exit 1
    }
