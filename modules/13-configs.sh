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
font-size = 13

theme = Catppuccin Mocha

cursor-style = bar
cursor-style-blink = true

window-padding-x = 14
window-padding-y = 12

copy-on-select = true
clipboard-read = allow
clipboard-write = allow

confirm-close-surface = false
shell-integration = zsh

window-decoration = true
window-save-state = always
EOF

cat > ~/.config/yazi/yazi.toml << 'EOF'
[mgr]
show_hidden = true
sort_by = "alphabetical"
sort_sensitive = false
linemode = "size"
show_symlink = true

[preview]
wrap = "yes"
tab_size = 2
EOF

#################################
# tmux
#################################

cat > ~/.tmux.conf << 'EOF'
set -g mouse on

set -g history-limit 100000
set -g renumber-windows on
set -g status-position top
set -g status-style 'bg=#1e1e2e,fg=#cdd6f4'
set -g status-left '#[fg=#89b4fa,bold] #S '
set -g status-right '#[fg=#a6e3a1]%Y-%m-%d #[fg=#f9e2af]%H:%M '
set -g pane-border-style 'fg=#45475a'
set -g pane-active-border-style 'fg=#89b4fa'

set -g default-terminal "screen-256color"

unbind C-b
set -g prefix C-a
bind C-a send-prefix

bind r source-file ~/.tmux.conf

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'

run '~/.tmux/plugins/tpm/tpm'
EOF

echo
echo "=================================="
echo " Configurations Installed"
echo "=================================="
echo
