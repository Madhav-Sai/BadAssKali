#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[+]${NC} $1"
}

log "Updating repositories..."

sudo apt update

log "Installing core packages..."

sudo apt install -y \
build-essential \
pkg-config \
software-properties-common \
curl \
wget \
git \
unzip \
zip \
tar \
gzip \
bzip2 \
xz-utils \
ca-certificates \
gnupg \
lsb-release

log "Installing terminal tools..."

sudo apt install -y \
zsh \
fzf \
tmux \
fastfetch \
eza \
bat \
ripgrep \
fd-find \
jq \
yq \
tree \
ncdu \
btop \
ranger \
nnn \
zoxide

log "Installing networking tools..."

sudo apt install -y \
net-tools \
dnsutils \
whois \
traceroute \
nmap \
tcpdump \
socat \
rlwrap

log "Installing Python tooling..."

sudo apt install -y \
python3 \
python3-full \
python3-pip \
python3-venv \
pipx

log "Installing Ghostty dependencies..."

sudo apt install -y \
libgtk-4-dev \
libadwaita-1-dev \
blueprint-compiler \
gettext \
libxml2-utils \
libfontconfig1-dev \
libfreetype-dev

log "Installing development tools..."

sudo apt install -y \
clang \
cmake \
ninja-build \
make

log "Installing clipboard support..."

sudo apt install -y \
wl-clipboard \
xclip

log "Installing quality-of-life tools..."

sudo apt install -y \
htop \
screen \
pv \
rename

log "Cleaning package cache..."

sudo apt autoremove -y

log "Package installation complete."