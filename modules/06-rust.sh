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

ARCH=$(uname -m)

case "$ARCH" in
    x86_64|aarch64|arm64)
        ;;
    *)
        error "Unsupported architecture: $ARCH"
        ;;
esac

if command -v rustup >/dev/null 2>&1; then

    log "Rustup already installed."

    source "$HOME/.cargo/env"

    log "Updating Rust toolchain..."

    rustup update

    rustup default stable

else

    log "Installing Rustup..."

    curl --proto '=https' \
         --tlsv1.2 \
         -sSf \
         https://sh.rustup.rs | sh -s -- -y

    source "$HOME/.cargo/env"

    rustup default stable

fi

log "Installing useful components..."

rustup component add rustfmt || true
rustup component add clippy || true

log "Verifying installation..."

cargo --version
rustc --version

log "Creating Cargo environment file..."

mkdir -p ~/.config/kali-beast

cat > ~/.config/kali-beast/rust.env << 'EOF'
export PATH="$HOME/.cargo/bin:$PATH"
EOF

if ! grep -q ".cargo/bin" ~/.zshrc 2>/dev/null; then

cat >> ~/.zshrc << 'EOF'

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

EOF

fi

echo
echo "=================================="
echo " Rust Installed"
echo "=================================="
echo

cargo --version
rustc --version