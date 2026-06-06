#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

FAILED=()
START_TIME=$(date +%s)

log() {
echo -e "${GREEN}[+]${NC} $1"
}

warn() {
echo -e "${YELLOW}[!]${NC} $1"
}

error() {
echo -e "${RED}[-]${NC} $1"
}

banner() {
echo
echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}     Kali Beast Bootstrap${NC}"
echo -e "${BLUE}==================================${NC}"
echo
}

finish() {

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo

if [[ ${#FAILED[@]} -eq 0 ]]; then

    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN} INSTALL COMPLETE${NC}"
    echo -e "${GREEN}==================================${NC}"

else

    echo -e "${RED}==================================${NC}"
    echo -e "${RED} INSTALL COMPLETED WITH ERRORS${NC}"
    echo -e "${RED}==================================${NC}"

    echo
    echo "Failed Modules:"

    for module in "${FAILED[@]}"
    do
        echo "  - $module"
    done

fi

echo
echo "Elapsed Time: ${ELAPSED}s"
echo

echo "Next Steps:"
echo
echo "  source ~/.zshrc"
echo "  p10k configure"
echo "  atuin import auto"
echo "  ./verify.sh"
echo

}

trap finish EXIT

banner

if [[ ! -d "$ROOT_DIR/modules" ]]; then

error "modules directory not found."

exit 1

fi

log "Making modules executable..."

chmod +x "$ROOT_DIR"/modules/*.sh

echo
echo "Detected Modules:"
echo

for module in "$ROOT_DIR"/modules/*.sh
do
echo "  - $(basename "$module")"
done

echo

read -rp "Continue installation? [Y/n] " CONFIRM

CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then

warn "Installation cancelled."

exit 0

fi

echo

for module in "$ROOT_DIR"/modules/*.sh
do

MODULE_NAME=$(basename "$module")

echo
echo "----------------------------------"
echo "Running: $MODULE_NAME"
echo "----------------------------------"
echo

if bash "$module"; then

    log "$MODULE_NAME completed."

else

    error "$MODULE_NAME failed."

    FAILED+=("$MODULE_NAME")

fi

done

echo

if [[ ${#FAILED[@]} -eq 0 ]]; then

log "All modules completed successfully."

else

warn "Some modules failed."

fi
