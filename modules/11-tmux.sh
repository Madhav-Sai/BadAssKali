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

error() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

if ! command -v tmux >/dev/null 2>&1; then

    error "tmux not installed."

fi

log "Installing TPM..."

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then

    git clone \
    https://github.com/tmux-plugins/tpm \
    "$HOME/.tmux/plugins/tpm"

else

    warn "TPM already installed."

fi

log "Creating tmux configuration..."

cat > "$HOME/.tmux.conf" << 'EOF'

# Prefix
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Mouse
set -g mouse on

# History
set -g history-limit 100000

# Vi mode
setw -g mode-keys vi

# Faster escape
set -sg escape-time 10

# Better terminal
set -g default-terminal "screen-256color"

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# Split panes
bind | split-window -h
bind - split-window -v

# Status bar
set -g status-position top

# TPM Plugins
set -g @plugin 'tmux-plugins/tpm'

set -g @plugin 'tmux-plugins/tmux-sensible'

set -g @plugin 'tmux-plugins/tmux-resurrect'

set -g @plugin 'tmux-plugins/tmux-continuum'

# Continuum
set -g @continuum-restore 'on'

run '~/.tmux/plugins/tpm/tpm'

EOF

log "Installing tmux plugins..."

if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then

    "$HOME/.tmux/plugins/tpm/bin/install_plugins"

fi

echo
echo "=================================="
echo " tmux Installed"
echo "=================================="
echo

echo "Start tmux with:"
echo
echo "  tmux"
echo

echo "Inside tmux:"
echo
echo "  Prefix = Ctrl+A"
echo "  Reload = Prefix + r"
echo