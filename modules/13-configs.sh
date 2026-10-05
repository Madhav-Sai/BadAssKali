#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/state.sh
source "$ROOT_DIR/lib/state.sh"

GREEN="\033[0;32m"
log() { echo -e "${GREEN}[+]\033[0m $1"; }

echo
echo "=================================="
echo " Configuration Files"
echo "=================================="
echo

mkdir -p "$HOME/.config/ghostty" "$HOME/.config/yazi"
mkdir -p "$HOME/htb-boxes" "$HOME/notes" "$HOME/tools" "$HOME/screenshots"

ghostty_content="$(mktemp -t badasskali-ghostty-config.XXXXXX)"
yazi_content="$(mktemp -t badasskali-yazi-config.XXXXXX)"
tmux_content="$(mktemp -t badasskali-tmux-config.XXXXXX)"
vim_content="$(mktemp -t badasskali-vim-config.XXXXXX)"
nano_content="$(mktemp -t badasskali-nano-config.XXXXXX)"
trap 'rm -f -- "$ghostty_content" "$yazi_content" "$tmux_content" "$vim_content" "$nano_content"' EXIT

cat >"$ghostty_content" <<'EOF'
font-family = JetBrainsMono Nerd Font
font-size = 13
font-feature = calt

theme = Catppuccin Mocha
background-opacity = 0.96
background-opacity-cells = true

cursor-style = bar
cursor-style-blink = true
cursor-click-to-move = true
mouse-hide-while-typing = true

window-padding-x = 14
window-padding-y = 12
window-padding-balance = true
window-save-state = always
window-subtitle = working-directory
resize-overlay = after-first

copy-on-select = true
clipboard-read = allow
clipboard-write = allow
confirm-close-surface = false

term = xterm-256color
macos-option-as-alt = true
shell-integration = zsh
shell-integration-features = cursor,sudo,title,ssh-env,ssh-terminfo
scroll-to-bottom = keystroke
unfocused-split-opacity = 0.88
split-divider-color = #89b4fa
split-preserve-zoom = navigation

keybind = ctrl+shift+d=new_split:right
keybind = ctrl+shift+e=new_split:down
keybind = ctrl+shift+h=goto_split:left
keybind = ctrl+shift+j=goto_split:down
keybind = ctrl+shift+k=goto_split:up
keybind = ctrl+shift+l=goto_split:right
keybind = ctrl+shift+enter=toggle_split_zoom
keybind = ctrl+shift+equal=equalize_splits
EOF

cat >"$yazi_content" <<'EOF'
[mgr]
show_hidden = true
sort_by = "alphabetical"
sort_sensitive = false
sort_dir_first = true
linemode = "size"
show_symlink = true
scrolloff = 5

[preview]
wrap = "yes"
tab_size = 2
max_width = 1200
max_height = 900

[tasks]
micro_workers = 10
macro_workers = 20
EOF

cat >"$tmux_content" <<'EOF'
# Stock tmux: default prefix (Ctrl+b), keys, and status bar.
# Only the terminal type is set so colors work and nano/vim behave.
set -g default-terminal "tmux-256color"
set -as terminal-features ',xterm-256color:RGB,xterm-ghostty:RGB'

EOF

cat >"$vim_content" <<'EOF'
set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set backspace=indent,eol,start
set t_Co=256
if has('termguicolors') && $COLORTERM =~# 'truecolor\|24bit'
    set termguicolors
endif
set number
set ruler
set showcmd
set wildmenu
set hlsearch incsearch ignorecase smartcase
set expandtab shiftwidth=4 softtabstop=4
set autoindent
set mouse=a
set ttimeout ttimeoutlen=10
set hidden
set nobackup noswapfile
set background=dark
EOF

cat >"$nano_content" <<'EOF'
set mouse
set linenumbers
set autoindent
set tabsize 4
set tabstospaces
set smooth
set softwrap
set historylog
include "/usr/share/nano/*.nanorc"
include "/opt/homebrew/share/nano/*.nanorc"
EOF

if [[ "${BADASSKALI_CONFIG_MODE:-merge}" == "replace" ]]; then
    backup_path "$HOME/.config/ghostty/config"
    backup_path "$HOME/.tmux.conf"
    install -m 0644 "$ghostty_content" "$HOME/.config/ghostty/config"
    install -m 0644 "$tmux_content" "$HOME/.tmux.conf"
    backup_path "$HOME/.vimrc"
    backup_path "$HOME/.nanorc"
    install -m 0644 "$vim_content" "$HOME/.vimrc"
    install -m 0644 "$nano_content" "$HOME/.nanorc"
else
    replace_managed_block "$HOME/.config/ghostty/config" terminal "$ghostty_content"
    replace_managed_block "$HOME/.tmux.conf" terminal "$tmux_content"
    replace_managed_block "$HOME/.vimrc" terminal "$vim_content" '"'
    replace_managed_block "$HOME/.nanorc" terminal "$nano_content"
fi

# TOML tables cannot safely be duplicated, so this file is backed up and replaced.
backup_path "$HOME/.config/yazi/yazi.toml"
install -m 0644 "$yazi_content" "$HOME/.config/yazi/yazi.toml"

log "Ghostty, Yazi, and tmux configurations installed with rollback support."
