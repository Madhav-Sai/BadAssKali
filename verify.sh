#!/usr/bin/env bash

set -uo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"
PROFILE="terminal"
JSON=false
PASSED=0
FAILED=0
RESULTS=()

usage() {
    cat <<'EOF'
Usage: ./verify.sh [--profile core|terminal|pentest|full] [--json]
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            [[ $# -ge 2 ]] || {
                echo "--profile requires a value" >&2
                exit 2
            }
            PROFILE="$2"
            shift 2
            ;;
        --json)
            JSON=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

[[ "$PROFILE" =~ ^(core|terminal|pentest|full)$ ]] || {
    echo "Invalid profile: $PROFILE" >&2
    exit 2
}

check_command() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        PASSED=$((PASSED + 1))
        RESULTS+=("ok:$tool")
        $JSON || echo -e "${GREEN}[OK]${NC} $tool"
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("missing:$tool")
        $JSON || echo -e "${RED}[FAIL]${NC} $tool"
    fi
}

check_file() {
    local label="$1" path="$2"
    if [[ -r "$path" ]]; then
        PASSED=$((PASSED + 1))
        RESULTS+=("ok:$label")
        $JSON || echo -e "${GREEN}[OK]${NC} $label"
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("missing:$label")
        $JSON || echo -e "${RED}[FAIL]${NC} $label"
    fi
}

core_tools=(git curl zsh tmux fastfetch fzf zoxide eza)
terminal_tools=(cargo rustc atuin thefuck yazi ghostty ncdu tldr http)
security_tools=(netexec certipy ffuf feroxbuster gobuster rustscan nmap)
workflow_tools=(nuclei subfinder httpx naabu dnsx katana autorecon bak-engage bak-recon)

if ! $JSON; then
    echo
    echo "=================================="
    echo " BadAssKali Verification ($PROFILE)"
    echo "=================================="
    echo
fi

for tool in "${core_tools[@]}"; do check_command "$tool"; done
if [[ "$PROFILE" != "core" ]]; then
    for tool in "${terminal_tools[@]}"; do check_command "$tool"; done
fi
if [[ "$PROFILE" == "pentest" || "$PROFILE" == "full" ]]; then
    for tool in "${security_tools[@]}"; do check_command "$tool"; done
    for tool in "${workflow_tools[@]}"; do check_command "$tool"; done
fi

check_file "managed aliases" "$HOME/.config/badasskali/aliases.zsh"
check_file "zsh configuration" "$HOME/.zshrc"
check_file "tmux configuration" "$HOME/.tmux.conf"

if $JSON; then
    printf '{"profile":"%s","passed":%d,"failed":%d,"results":[' "$PROFILE" "$PASSED" "$FAILED"
    for ((index = 0; index < ${#RESULTS[@]}; index++)); do
        ((index > 0)) && printf ','
        state="${RESULTS[$index]%%:*}"
        name="${RESULTS[$index]#*:}"
        printf '{"name":"%s","status":"%s"}' "$name" "$state"
    done
    printf ']}\n'
else
    echo
    echo -e "${GREEN}Passed:${NC} $PASSED"
    echo -e "${RED}Failed:${NC} $FAILED"
    [[ "$FAILED" -eq 0 ]] &&
        echo -e "${GREEN}Selected profile looks healthy.${NC}" ||
        echo -e "${YELLOW}Some selected-profile requirements are missing.${NC}"
fi

[[ "$FAILED" -eq 0 ]]
