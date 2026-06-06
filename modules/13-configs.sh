#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

log "Generating ZSH configuration..."

cat > ~/.zshrc << 'EOF'
#################################
# Kali Beast ZSH
#################################

export ZSH="$HOME/.oh-my-zsh"

#################################
# Theme
#################################

ZSH_THEME="powerlevel10k/powerlevel10k"

#################################
# Plugins
#################################

plugins=(
git
sudo
fzf
zoxide
zsh-autosuggestions
zsh-syntax-highlighting
zsh-completions
fzf-tab
)

source $ZSH/oh-my-zsh.sh

#################################
# PATH
#################################

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.atuin/bin:$PATH"
export PATH="$HOME/.venvs/thefuck/bin:$PATH"

#################################
# Powerlevel10k
#################################

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

#################################
# Atuin
#################################

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

#################################
# TheFuck
#################################

if [ -x "$HOME/.venvs/thefuck/bin/thefuck" ]; then
    eval "$($HOME/.venvs/thefuck/bin/thefuck --alias)"
fi

#################################
# Zoxide
#################################

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

#################################
# History
#################################

HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

#################################
# Disable annoying corrections
#################################

unsetopt CORRECT
unsetopt CORRECT_ALL

#################################
# Better completion
#################################

autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list \
'm:{a-z}={A-Za-z}'

zstyle ':completion:*' menu select

#################################
# Colors
#################################

export CLICOLOR=1

#################################
# Aliases
#################################

alias ls='eza --icons'
alias ll='eza -lah --icons'
alias la='eza -a --icons'
alias lt='eza --tree --icons'

alias cat='batcat'

#################################
# Pentest Profile
#################################

[[ -f ~/.config/kali-beast/pentest.zsh ]] && \
source ~/.config/kali-beast/pentest.zsh

#################################
# Fastfetch
#################################

if command -v fastfetch >/dev/null 2>&1; then

    if [[ "$TERM_PROGRAM" == "ghostty" ]] && \
       [[ "$SHLVL" -eq 1 ]]; then

        fastfetch

    fi

fi

EOF

#################################
# Ghostty
#################################

log "Creating Ghostty configuration..."

mkdir -p ~/.config/ghostty

cat > ~/.config/ghostty/config << 'EOF'
theme = Tokyo Night

font-family = JetBrainsMono Nerd Font
font-size = 14

background-opacity = 0.95

window-padding-x = 10
window-padding-y = 10

cursor-style = block

copy-on-select = true

mouse-hide-while-typing = true

gtk-titlebar = false

confirm-close-surface = false

shell-integration = zsh

clipboard-read = allow
clipboard-write = allow
EOF

echo
echo "=================================="
echo " Configuration Complete"
echo "=================================="
echo
echo "Run:"
echo
echo "    source ~/.zshrc"
echo
echo "Then:"
echo
echo "    p10k configure"
echo