#!/usr/bin/env bash

set -Eeuo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

echo
echo "=================================="
echo "     Ghostty Installation"
echo "=================================="
echo

if command -v ghostty >/dev/null 2>&1; then
    warn "Ghostty is already installed."
    ghostty --version || true
    exit 0
fi

case "$(uname -m)" in
    x86_64) zig_arch="x86_64-linux" ;;
    aarch64|arm64) zig_arch="aarch64-linux" ;;
    *) fail "Unsupported architecture: $(uname -m)" ;;
esac

log "Installing build dependencies..."
sudo apt update
sudo apt install -y \
    build-essential ca-certificates curl git jq pkg-config xz-utils \
    libadwaita-1-dev libegl1-mesa-dev libfontconfig-dev libfreetype-dev \
    libglib2.0-dev libgtk-4-dev libgtk4-layer-shell-dev libharfbuzz-dev \
    libwayland-dev libx11-dev libxcursor-dev libxi-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxml2-utils libxrandr-dev wayland-protocols

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

log "Cloning the latest stable Ghostty release..."
git clone --depth=1 --branch "$(git ls-remote --tags --refs https://github.com/ghostty-org/ghostty.git \
    | awk -F/ '{print $3}' | grep '^v[0-9]' | sort -V | tail -n1)" \
    https://github.com/ghostty-org/ghostty.git "$work_dir/ghostty"

zig_version=$(awk -F'"' '/minimum_zig_version/ {print $2; exit}' "$work_dir/ghostty/build.zig.zon")
[[ -n "$zig_version" ]] || fail "Unable to determine Ghostty's required Zig version."

zig_dir="$HOME/.local/opt/zig-$zig_version"
zig_bin="$zig_dir/zig"

if [[ ! -x "$zig_bin" ]]; then
    log "Installing Zig $zig_version for this Ghostty build..."
    mkdir -p "$HOME/.local/opt"
    curl -fL "https://ziglang.org/download/$zig_version/zig-$zig_arch-$zig_version.tar.xz" \
        -o "$work_dir/zig.tar.xz"
    tar -xf "$work_dir/zig.tar.xz" -C "$work_dir"
    mv "$work_dir/zig-$zig_arch-$zig_version" "$zig_dir"
fi

log "Building Ghostty with Zig $zig_version..."
cd "$work_dir/ghostty"
"$zig_bin" build -Doptimize=ReleaseFast

log "Installing Ghostty..."
sudo env PATH="$(dirname "$zig_bin"):$PATH" "$zig_bin" build install \
    -Doptimize=ReleaseFast --prefix /usr/local

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/ghostty.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Ghostty
Comment=Fast, feature-rich terminal emulator
Exec=ghostty
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
command -v ghostty >/dev/null 2>&1 || fail "Ghostty installation failed."

log "Ghostty $(ghostty --version) installed successfully."
