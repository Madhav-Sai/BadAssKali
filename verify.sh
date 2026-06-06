#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

PASSED=0
FAILED=0

check() {

    local tool="$1"

    if command -v "$tool" >/dev/null 2>&1; then

        echo -e "${GREEN}[OK]${NC} $tool"

        ((PASSED++))

    else

        echo -e "${RED}[FAIL]${NC} $tool"

        ((FAILED++))

    fi

}

echo
echo "=================================="
echo " Kali Beast Verification"
echo "=================================="
echo

check git
check curl
check wget
check zsh
check tmux
check cargo
check rustc
check atuin
check thefuck
check yazi
check ghostty
check fastfetch
check fzf
check zoxide
check eza
check batcat

echo
echo "Security Tools"
echo "--------------"

check netexec
check certipy
check ffuf
check feroxbuster
check gobuster
check rustscan

echo
echo "=================================="
echo " Results"
echo "=================================="
echo

echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"

echo

if [[ $FAILED -eq 0 ]]; then

    echo -e "${GREEN}System looks healthy.${NC}"

else

    echo -e "${YELLOW}Some tools are missing.${NC}"

fi

echo