#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"

echo
echo "=================================="
echo " AutoRecon Service Enumeration"
echo "=================================="
echo

detect_platform || {
    echo "[-] Unable to detect a supported package manager." >&2
    exit 1
}

export PATH="$HOME/.local/bin:$PATH"
if have_cmd autorecon; then
    echo "[+] AutoRecon is already installed."
    autorecon --version 2>/dev/null || true
    exit 0
fi

pkg_update
if pkg_available autorecon; then
    pkg_install autorecon
else
    dependencies=(
        curl dnsrecon enum4linux-ng feroxbuster gobuster impacket-scripts
        nbtscan nikto nmap onesixtyone redis-tools seclists smbclient smbmap
        snmp sslscan sipvicious whatweb python3-venv pipx
    )
    available=()
    for dependency in "${dependencies[@]}"; do
        if pkg_available "$dependency"; then
            available+=("$dependency")
        else
            echo "[!] Optional AutoRecon dependency unavailable: $dependency"
        fi
    done
    pkg_install "${available[@]}"
    command -v pipx >/dev/null 2>&1 || {
        echo "[-] pipx is required for an isolated AutoRecon installation." >&2
        exit 1
    }
    pipx install --force git+https://github.com/Tib3rius/AutoRecon.git
fi

command -v autorecon >/dev/null 2>&1 || {
    echo "[-] AutoRecon installation failed." >&2
    exit 1
}

echo "[+] AutoRecon installed. Run it only against explicitly authorized targets."
