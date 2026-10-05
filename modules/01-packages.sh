#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/platform.sh
source "$ROOT_DIR/lib/platform.sh"
detect_platform || {
    echo "[-] Unable to detect the package manager." >&2
    exit 1
}

echo
echo "=================================="
echo " Installing Base Packages"
echo "=================================="
echo

case "$BAK_PACKAGE_FAMILY" in
    debian)
        packages=(
            git curl wget unzip zip tar gzip bzip2 xz-utils build-essential
            pkg-config software-properties-common apt-transport-https
            ca-certificates gnupg lsb-release fontconfig jq yq tree htop btop fastfetch
            fzf ripgrep fd-find bat eza zoxide ranger neovim tmux python3
            python3-pip python3-venv pipx direnv entr httpie ncdu shellcheck
            shfmt tealdeer w3m net-tools dnsutils nmap smbclient ldap-utils seclists
        )
        ;;
    arch)
        packages=(
            base-devel git curl wget unzip zip tar gzip bzip2 xz pkgconf
            ca-certificates gnupg jq yq tree htop btop fastfetch fzf ripgrep fd
            bat eza zoxide ranger neovim tmux python python-pip python-pipx
            direnv entr httpie ncdu shellcheck shfmt tealdeer w3m bind nmap
            smbclient openldap seclists
        )
        ;;
    fedora)
        packages=(
            @development-tools git curl wget unzip zip tar gzip bzip2 xz
            pkgconf-pkg-config ca-certificates gnupg2 jq yq tree htop btop
            fastfetch fzf ripgrep fd-find bat eza zoxide ranger neovim tmux
            python3 python3-pip pipx direnv entr httpie ncdu ShellCheck shfmt
            tealdeer w3m bind-utils nmap samba-client openldap-clients
        )
        ;;
    suse)
        packages=(
            gcc gcc-c++ make git curl wget unzip zip tar gzip bzip2 xz
            pkg-config ca-certificates gpg2 jq yq tree htop fzf ripgrep fd bat
            zoxide ranger neovim tmux python3 python3-pip pipx direnv entr httpie
            ncdu ShellCheck w3m bind-utils nmap samba-client openldap2-client
        )
        ;;
esac

pkg_update

if [[ "$BAK_OS_ID" == "parrot" ]]; then
    echo "[+] Parrot OS detected; using its configured APT repositories without adding Kali sources."
    if ! pkg_available parrot-core; then
        echo "[-] The Parrot repository is not healthy: parrot-core was not found." >&2
        echo "    Check /etc/apt/sources.list.d/parrot.list and run: sudo parrot-upgrade" >&2
        exit 1
    fi
fi

available=()
for package in "${packages[@]}"; do
    if [[ "$package" == @* ]] ||
        pkg_installed "$package" ||
        pkg_available "$package"; then
        available+=("$package")
    else
        echo "[!] Skipping unavailable base package: $package"
    fi
done

pkg_install "${available[@]}"
if [[ "${BADASSKALI_DOWNLOAD_ONLY:-false}" == "true" ]]; then
    echo "[+] Base packages downloaded to ${BADASSKALI_CACHE_DIR:-$HOME/.cache/badasskali/packages}."
    exit 0
fi
command -v git >/dev/null 2>&1 || {
    echo "[-] Base package installation failed." >&2
    exit 1
}
echo "[+] Installed available base packages for $BAK_PACKAGE_FAMILY."
