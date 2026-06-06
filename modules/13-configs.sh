#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo
echo "=================================="
echo " Configuration Files"
echo "=================================="
echo

mkdir -p ~/.config
mkdir -p ~/.config/ghostty
mkdir -p ~/.config/yazi
mkdir -p ~/htb-boxes
mkdir -p ~/notes
mkdir -p ~/tools
mkdir -p ~/screenshots

#################################
# Ghostty
#################################

cat > ~/.config/ghostty/config << 'EOF'
font-family = JetBrainsMono Nerd Font
font-size = 12

theme = Dracula

cursor-style = block

window-padding-x = 8
window-padding-y = 8

copy-on-select = true

confirm-close-surface = false
shell-integration = zsh
EOF

#################################
# tmux
#################################

cat > ~/.tmux.conf << 'EOF'
set -g mouse on

set -g history-limit 100000

set -g default-terminal "screen-256color"

unbind C-b
set -g prefix C-a
bind C-a send-prefix

bind r source-file ~/.tmux.conf

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'

run '~/.tmux/plugins/tpm/tpm'
EOF

#################################
# Yazi
#################################

cat > ~/.config/yazi/yazi.toml << 'EOF'
[manager]
show_hidden = true
sort_by = "alphabetical"
sort_sensitive = false
linemode = "size"
EOF

echo
echo "=================================="
echo " Configurations Installed"
echo "=================================="
echo