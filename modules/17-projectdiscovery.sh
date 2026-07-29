#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"
# shellcheck source=lib/state.sh
source "$ROOT_DIR/lib/state.sh"

echo
echo "=================================="
echo " ProjectDiscovery Toolkit"
echo "=================================="
echo

detect_platform || {
    echo "[-] Unable to detect a supported package manager." >&2
    exit 1
}

export PATH="$HOME/.local/bin:$HOME/.pdtm/go/bin:$HOME/go/bin:$PATH"
mkdir -p "$HOME/.local/bin"

if ! command -v go >/dev/null 2>&1; then
    echo "[+] Installing Go for the ProjectDiscovery tool manager..."
    pkg_update
    case "$BAK_PACKAGE_FAMILY" in
        debian) pkg_install golang-go ;;
        arch) pkg_install go ;;
        fedora | suse) pkg_install go ;;
    esac
fi

command -v go >/dev/null 2>&1 || {
    echo "[-] Go is required to install pdtm." >&2
    exit 1
}

if ! command -v pdtm >/dev/null 2>&1; then
    echo "[+] Installing the official ProjectDiscovery tool manager..."
    GOBIN="$HOME/.local/bin" go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
fi

command -v pdtm >/dev/null 2>&1 || {
    echo "[-] pdtm installation failed. Check the Go version and network connection." >&2
    exit 1
}

tools="nuclei,subfinder,httpx,naabu,dnsx,katana,tlsx,uncover"
echo "[+] Installing maintained reconnaissance tools: $tools"
pdtm -i "$tools"

path_block="$(mktemp -t badasskali-pdtm-path.XXXXXX)"
trap 'rm -f -- "$path_block"' EXIT
cat >"$path_block" <<'EOF'
export PATH="$HOME/.pdtm/go/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"
EOF
replace_managed_block "$HOME/.zshrc" projectdiscovery-path "$path_block"

export PATH="$HOME/.pdtm/go/bin:$PATH"
missing=()
for tool in nuclei subfinder httpx naabu dnsx katana tlsx; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "[-] Missing ProjectDiscovery tools: ${missing[*]}" >&2
    exit 1
fi

echo "[+] ProjectDiscovery toolkit installed."
echo "    Reload with: source ~/.zshrc"
