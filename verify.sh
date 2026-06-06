#!/usr/bin/env bash

echo
echo "===== Kali Beast Verification ====="
echo

check() {

    if command -v "$1" >/dev/null 2>&1; then
        echo "[OK] $1"
    else
        echo "[FAIL] $1"
    fi
}

check zsh
check git
check cargo
check rustc
check ghostty
check atuin
check thefuck
check tmux
check yazi
check fastfetch
check eza
check batcat
check zoxide

echo
echo "Verification complete."