#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

echo
echo "=================================="
echo " Powerlevel10k Configuration"
echo "=================================="
echo

cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Rust / Cargo
export PATH="$HOME/.cargo/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"


ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    sudo
    docker
    python
    pip
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
    direnv
)

source $ZSH/oh-my-zsh.sh

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Atuin
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# TheFuck
command -v thefuck >/dev/null && eval "$(thefuck --alias)"

# Zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# Yazi: change the current shell to the directory selected in Yazi.
function y() {
    local tmp_file="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp_file"
    if [[ -f "$tmp_file" ]]; then
        local cwd
        cwd="$(cat -- "$tmp_file")"
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
        rm -f -- "$tmp_file"
    fi
}

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# History substring search
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down

# User aliases
[ -f ~/.aliases ] && source ~/.aliases

# Better history
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Disable annoying autocorrect
unsetopt correct
unsetopt correctall

# Fastfetch
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
EOF

log ".zshrc created."

echo
echo "=================================="
echo " Powerlevel10k Configured"
echo "=================================="
echo

echo "Run:"
echo
echo "source ~/.zshrc"
echo "p10k configure"
echo
