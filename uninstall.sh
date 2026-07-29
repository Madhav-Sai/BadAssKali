#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
ASSUME_YES=false
RESTORE_BACKUPS=false
PROFILE="full"
ONLY=""

usage() {
    cat <<'EOF'
BadAssKali selective uninstaller

Usage: ./uninstall.sh [options]

  --only LIST          Remove selected components (comma-separated)
  --profile PROFILE    core, terminal, pentest, or full (default: full)
  --restore-backups    Restore the latest configuration snapshot afterward
  --dry-run            Show what would change
  -y, --yes            Skip confirmation
  -h, --help           Show help

Components: aliases configs management ghostty tmux ohmyzsh prompt fonts rust
            atuin thefuck yazi projectdiscovery autorecon engagement recon
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            [[ $# -ge 2 ]] || {
                echo "--only requires a list" >&2
                exit 1
            }
            ONLY="$2"
            shift 2
            ;;
        --profile)
            [[ $# -ge 2 ]] || {
                echo "--profile requires a value" >&2
                exit 1
            }
            PROFILE="$2"
            shift 2
            ;;
        --restore-backups)
            RESTORE_BACKUPS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            ASSUME_YES=true
            shift
            ;;
        -y | --yes)
            ASSUME_YES=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

[[ "$PROFILE" =~ ^(core|terminal|pentest|full)$ ]] || {
    echo "Invalid profile: $PROFILE" >&2
    exit 1
}

if [[ -n "$ONLY" ]]; then
    IFS=',' read -r -a components <<<"$ONLY"
elif [[ "$PROFILE" == "core" ]]; then
    components=(aliases configs management prompt fonts ohmyzsh)
else
    components=(aliases configs management prompt fonts ohmyzsh ghostty tmux rust atuin thefuck yazi projectdiscovery autorecon engagement recon)
fi

echo "Components selected for removal:"
printf '  - %s\n' "${components[@]}"

if ! $ASSUME_YES; then
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

run() {
    if $DRY_RUN; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

remove_path() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0
    if [[ -d "$target" && ! -L "$target" ]]; then
        run rm -rf -- "$target"
    else
        run rm -f -- "$target"
    fi
}

remove_block() {
    local target="$1" block="$2"
    [[ -r "$target" ]] || return 0
    local temporary
    temporary="$(mktemp -t badasskali-uninstall.XXXXXX)"
    awk -v begin="# >>> BADASSKALI:${block} >>>" -v end="# <<< BADASSKALI:${block} <<<" '
        $0 == begin { skipping=1; next }
        $0 == end { skipping=0; next }
        !skipping { print }
    ' "$target" >"$temporary"
    if $DRY_RUN; then
        echo "[dry-run] remove managed block $block from $target"
    else
        install -m 0644 "$temporary" "$target"
    fi
    rm -f -- "$temporary"
}

for component in "${components[@]}"; do
    component="${component//[[:space:]]/}"
    case "$component" in
        aliases)
            if [[ -r "$HOME/.aliases" ]]; then
                if $DRY_RUN; then
                    echo "[dry-run] remove BadAssKali source lines from $HOME/.aliases"
                else
                    sed '/# BADASSKALI_ALIASES/,+1d' "$HOME/.aliases" >"$HOME/.aliases.tmp"
                    mv "$HOME/.aliases.tmp" "$HOME/.aliases"
                fi
            fi
            remove_path "$HOME/.config/badasskali/aliases.zsh"
            remove_path "$HOME/.config/badasskali/alias-packs"
            remove_path "$HOME/.config/badasskali/enabled-alias-packs"
            ;;
        configs)
            remove_block "$HOME/.zshrc" shell
            remove_block "$HOME/.config/ghostty/config" terminal
            remove_block "$HOME/.config/ghostty/config" theme
            remove_block "$HOME/.tmux.conf" terminal
            remove_block "$HOME/.tmux.conf" theme
            remove_path "$HOME/.config/yazi/yazi.toml"
            ;;
        management)
            remove_path "$HOME/.local/bin/badasskali"
            ;;
        ghostty)
            if $DRY_RUN; then
                echo "[dry-run] bash modules/07-ghostty.sh --uninstall"
            else
                bash "$ROOT_DIR/modules/07-ghostty.sh" --uninstall
            fi
            ;;
        tmux) remove_path "$HOME/.tmux/plugins/tpm" ;;
        ohmyzsh) remove_path "$HOME/.oh-my-zsh" ;;
        prompt) remove_path "$HOME/.p10k.zsh" ;;
        fonts) remove_path "$HOME/.local/share/fonts/JetBrainsMono" ;;
        rust)
            if command -v rustup >/dev/null 2>&1; then run rustup self uninstall -y; fi
            ;;
        atuin) remove_path "$HOME/.atuin" ;;
        thefuck)
            if command -v uv >/dev/null 2>&1; then run uv tool uninstall thefuck; fi
            ;;
        yazi) echo "[!] Yazi package retained; remove it with your package manager if desired." ;;
        projectdiscovery)
            remove_block "$HOME/.zshrc" projectdiscovery-path
            remove_path "$HOME/.pdtm"
            remove_path "$HOME/.local/bin/pdtm"
            ;;
        autorecon)
            if command -v pipx >/dev/null 2>&1; then run pipx uninstall autorecon; fi
            echo "[!] A distribution-installed AutoRecon package is retained."
            ;;
        engagement)
            remove_path "$HOME/.local/bin/bak-engage"
            echo "[!] Existing engagement data under ~/Engagements was preserved."
            ;;
        recon) remove_path "$HOME/.local/bin/bak-recon" ;;
        "") ;;
        *) echo "[!] Unknown component skipped: $component" ;;
    esac
done

if $RESTORE_BACKUPS; then
    if $DRY_RUN; then
        echo "[dry-run] badasskali rollback --yes"
    else
        "$ROOT_DIR/badasskali" rollback --yes
    fi
fi

echo "[+] Uninstall operation complete."
