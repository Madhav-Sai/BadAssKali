#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODULES=(
    00-os-detect.sh
    01-packages.sh
    02-zsh.sh
    03-ohmyzsh.sh
    04-p10k.sh
    05-fonts.sh
    06-rust.sh
    07-ghostty.sh
    08-atuin.sh
    09-thefuck.sh
    10-yazi.sh
    11-tmux.sh
    12-pentest.sh
    13-configs.sh
    14-cargo-tools.sh
    15-security-tools.sh
    16-management.sh
    17-projectdiscovery.sh
    18-autorecon.sh
    19-engagement-workspace.sh
    20-recon-workflow.sh
)

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

FAILED=()
SELECTED_MODULES=()
SKIP_MODULES=()
ONLY_MODULES=()
PROFILE="full"
ASSUME_YES=false
DRY_RUN=false
FAIL_FAST=false
GHOSTTY_METHOD="auto"
GHOSTTY_PREFIX="user"
GHOSTTY_VERSION=""
GHOSTTY_FORCE=false
GHOSTTY_KEEP_BUILD=false
GHOSTTY_CHANNEL="stable"
GHOSTTY_BUILD_JOBS=""
GHOSTTY_VERIFY=true
GHOSTTY_ACCEPT_COMMUNITY=false
INTERACTIVE=false
ADDONS=""
CONFIG_MODE="merge"
OFFLINE=false
DOWNLOAD_ONLY=false
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/badasskali/packages"
START_TIME=$(date +%s)
FINISH_ENABLED=false

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; }
die() {
    fail "$1"
    exit 1
}

usage() {
    cat <<'EOF'
BadAssKali modular installer

Usage: ./install.sh [options]

Profiles:
  --profile core       Shell, prompt, fonts, aliases, and configs
  --profile terminal   Core plus Rust, Ghostty, Atuin, Yazi, tmux, and tools
  --profile pentest    Complete pentesting workflow and engagement UX
  --profile full       Everything (currently equivalent to pentest; default)

Module selection:
  --only LIST          Run only comma-separated module names or numbers
  --skip LIST          Skip comma-separated module names or numbers
  --no-ghostty         Shortcut for --skip 07
  --list-modules       Show modules and profile membership, then exit
  --addons LIST        Install comma-separated optional add-on bundles
  --list-addons        Show optional add-on bundles, then exit

Ghostty:
  --ghostty-method M   auto, package, source, snap, or appimage (default: auto)
  --ghostty-prefix P   user or system for source builds (default: user)
  --ghostty-version V  Build a specific stable source version
  --ghostty-channel C  stable or tip (default: stable)
  --ghostty-build-jobs N
                        Limit parallel build jobs
  --no-ghostty-verify  Skip download verification after an explicit warning
  --accept-community-ghostty
                        Accept the trust boundary for community AppImages
  --force-ghostty      Reinstall Ghostty even when it is already available
  --keep-ghostty-build Preserve source/build files when troubleshooting

Execution:
  -y, --yes            Do not ask for confirmation
  --dry-run            Print the selected actions without running them
  --fail-fast          Stop after the first failed module
  --continue-on-error  Run remaining modules after failures (default)
  --interactive        Guided profile, Ghostty, and add-on selection
  --config-mode MODE   merge or replace managed configuration (default: merge)
  --cache-dir DIR      Package cache for download/offline operations
  --download-only      Download base/add-on packages without configuring them
  --offline            Use cached package data and avoid repository refreshes
  -h, --help           Show this help

Examples:
  ./install.sh --profile terminal --yes
  ./install.sh --only 07 --ghostty-method source --ghostty-prefix user
  ./install.sh --skip 09,15 --dry-run
EOF
}

normalize_module() {
    local requested="${1%.sh}"
    local module

    for module in "${MODULES[@]}"; do
        if [[ "$requested" == "${module%.sh}" || "$requested" == "${module%%-*}" ]]; then
            printf '%s\n' "$module"
            return 0
        fi
    done

    return 1
}

append_module_list() {
    local destination="$1"
    local raw_list="$2"
    local item normalized
    local -a parsed=()

    IFS=',' read -r -a parsed <<<"$raw_list"
    for item in "${parsed[@]}"; do
        item="${item//[[:space:]]/}"
        normalized="$(normalize_module "$item")" || die "Unknown module: $item"
        if [[ "$destination" == "only" ]]; then
            if [[ ${#ONLY_MODULES[@]} -eq 0 ]] ||
                ! contains "$normalized" "${ONLY_MODULES[@]}"; then
                ONLY_MODULES+=("$normalized")
            fi
        else
            if [[ ${#SKIP_MODULES[@]} -eq 0 ]] ||
                ! contains "$normalized" "${SKIP_MODULES[@]}"; then
                SKIP_MODULES+=("$normalized")
            fi
        fi
    done
}

contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

profile_includes() {
    local module="$1"
    local number="${module%%-*}"

    case "$PROFILE" in
        core)
            [[ "$number" =~ ^(00|01|02|03|04|05|12|13|16)$ ]]
            ;;
        terminal)
            [[ ! "$number" =~ ^(15|17|18|19|20)$ ]]
            ;;
        pentest)
            return 0
            ;;
        full)
            return 0
            ;;
    esac
}

list_modules() {
    local module number core terminal pentest
    printf '%-4s %-30s %-6s %-9s %-8s %-5s\n' "ID" "MODULE" "CORE" "TERMINAL" "PENTEST" "FULL"
    for module in "${MODULES[@]}"; do
        number="${module%%-*}"
        core="-"
        terminal="yes"
        pentest="yes"
        [[ "$number" =~ ^(00|01|02|03|04|05|12|13|16)$ ]] && core="yes"
        [[ "$number" =~ ^(15|17|18|19|20)$ ]] && terminal="-"
        printf '%-4s %-30s %-6s %-9s %-8s %-5s\n' "$number" "$module" "$core" "$terminal" "$pentest" "yes"
    done
}

interactive_setup() {
    [[ -t 0 ]] || die "--interactive requires a terminal."
    echo "Choose an installation profile:"
    echo "  1) core      Shell, prompt, aliases, and configs"
    echo "  2) terminal  Complete terminal and development workflow"
    echo "  3) pentest   Complete tools, recon workflows, and engagement UX"
    read -rp "Profile [2]: " choice
    case "${choice:-2}" in
        1 | core) PROFILE="core" ;;
        2 | terminal) PROFILE="terminal" ;;
        3 | pentest) PROFILE="pentest" ;;
        full) PROFILE="full" ;;
        *) die "Invalid profile selection." ;;
    esac

    read -rp "Install or manage Ghostty? [Y/n] " choice
    if [[ "${choice:-Y}" =~ ^[Nn]$ ]]; then
        SKIP_MODULES+=("07-ghostty.sh")
    else
        read -rp "Ghostty method (auto/package/source/snap/appimage) [auto]: " choice
        GHOSTTY_METHOD="${choice:-auto}"
        if [[ "$GHOSTTY_METHOD" == "appimage" ]]; then
            read -rp "Community AppImages have a different trust boundary. Accept it? [y/N] " choice
            [[ "$choice" =~ ^[Yy]$ ]] ||
                die "AppImage installation was not accepted."
            GHOSTTY_ACCEPT_COMMUNITY=true
        fi
    fi

    echo "Optional add-ons can be listed with: ./install.sh --list-addons"
    read -rp "Comma-separated add-ons (blank for none): " ADDONS
}

finish() {
    $FINISH_ENABLED || return 0

    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - START_TIME))

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
        echo "Failed modules:"
        printf '  - %s\n' "${FAILED[@]}"
    fi

    echo
    echo "Elapsed time: ${elapsed}s"
    echo
    echo "Next steps:"
    echo "  source ~/.zshrc"
    echo "  p10k configure"
    [[ "$PROFILE" == "core" ]] || echo "  atuin import auto"
    echo "  ./verify.sh --profile $PROFILE"
    echo
}

trap finish EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            [[ $# -ge 2 ]] || die "--profile requires core, terminal, or full."
            PROFILE="$2"
            shift 2
            ;;
        --only)
            [[ $# -ge 2 ]] || die "--only requires a comma-separated module list."
            append_module_list only "$2"
            shift 2
            ;;
        --skip)
            [[ $# -ge 2 ]] || die "--skip requires a comma-separated module list."
            append_module_list skip "$2"
            shift 2
            ;;
        --no-ghostty)
            SKIP_MODULES+=("07-ghostty.sh")
            shift
            ;;
        --addons)
            [[ $# -ge 2 ]] || die "--addons requires a comma-separated list."
            ADDONS="$2"
            shift 2
            ;;
        --list-addons)
            awk -F'|' '!/^#/ && NF >= 3 {printf "%-22s %-13s %s\n", $1, $2, $3}' "$ROOT_DIR/configs/addons.tsv"
            exit 0
            ;;
        --ghostty-method)
            [[ $# -ge 2 ]] || die "--ghostty-method requires auto, package, or source."
            GHOSTTY_METHOD="$2"
            shift 2
            ;;
        --ghostty-prefix)
            [[ $# -ge 2 ]] || die "--ghostty-prefix requires user or system."
            GHOSTTY_PREFIX="$2"
            shift 2
            ;;
        --ghostty-version)
            [[ $# -ge 2 ]] || die "--ghostty-version requires a version number."
            GHOSTTY_VERSION="$2"
            shift 2
            ;;
        --ghostty-channel)
            [[ $# -ge 2 ]] || die "--ghostty-channel requires stable or tip."
            GHOSTTY_CHANNEL="$2"
            shift 2
            ;;
        --ghostty-build-jobs)
            [[ $# -ge 2 ]] || die "--ghostty-build-jobs requires a positive number."
            GHOSTTY_BUILD_JOBS="$2"
            shift 2
            ;;
        --no-ghostty-verify)
            GHOSTTY_VERIFY=false
            shift
            ;;
        --accept-community-ghostty)
            GHOSTTY_ACCEPT_COMMUNITY=true
            shift
            ;;
        --force-ghostty)
            GHOSTTY_FORCE=true
            shift
            ;;
        --keep-ghostty-build)
            GHOSTTY_KEEP_BUILD=true
            shift
            ;;
        -y | --yes)
            ASSUME_YES=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            ASSUME_YES=true
            shift
            ;;
        --fail-fast)
            FAIL_FAST=true
            shift
            ;;
        --continue-on-error)
            FAIL_FAST=false
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --config-mode)
            [[ $# -ge 2 ]] || die "--config-mode requires merge or replace."
            CONFIG_MODE="$2"
            shift 2
            ;;
        --cache-dir)
            [[ $# -ge 2 ]] || die "--cache-dir requires a directory."
            CACHE_DIR="$2"
            shift 2
            ;;
        --download-only)
            DOWNLOAD_ONLY=true
            ASSUME_YES=true
            shift
            ;;
        --offline)
            OFFLINE=true
            shift
            ;;
        --list-modules)
            list_modules
            exit 0
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1 (run ./install.sh --help)"
            ;;
    esac
done

$INTERACTIVE && interactive_setup

[[ "$PROFILE" =~ ^(core|terminal|pentest|full)$ ]] || die "Unknown profile: $PROFILE"
[[ "$GHOSTTY_METHOD" =~ ^(auto|package|source|snap|appimage)$ ]] || die "Invalid Ghostty method: $GHOSTTY_METHOD"
[[ "$GHOSTTY_PREFIX" =~ ^(user|system)$ ]] || die "Invalid Ghostty prefix: $GHOSTTY_PREFIX"
[[ "$GHOSTTY_CHANNEL" =~ ^(stable|tip)$ ]] || die "Invalid Ghostty channel: $GHOSTTY_CHANNEL"
[[ -z "$GHOSTTY_BUILD_JOBS" || "$GHOSTTY_BUILD_JOBS" =~ ^[1-9][0-9]*$ ]] ||
    die "Ghostty build jobs must be a positive number."
[[ "$CONFIG_MODE" =~ ^(merge|replace)$ ]] || die "Invalid config mode: $CONFIG_MODE"
[[ -z "$GHOSTTY_VERSION" || "$GHOSTTY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    die "Ghostty version must look like 1.3.1."

if [[ ${#ONLY_MODULES[@]} -gt 0 ]]; then
    SELECTED_MODULES=("${ONLY_MODULES[@]}")
else
    for module in "${MODULES[@]}"; do
        profile_includes "$module" && SELECTED_MODULES+=("$module")
    done
fi

if $DOWNLOAD_ONLY; then
    download_selection=()
    contains "01-packages.sh" "${SELECTED_MODULES[@]}" && download_selection+=("01-packages.sh")
    if [[ ${#download_selection[@]} -eq 0 && -z "$ADDONS" ]]; then
        die "--download-only needs module 01 in the selected profile or at least one --addons bundle."
    fi
    [[ ${#download_selection[@]} -gt 0 ]] || download_selection+=("00-os-detect.sh")
    SELECTED_MODULES=("${download_selection[@]}")
fi

if [[ ${#SKIP_MODULES[@]} -gt 0 ]]; then
    filtered_modules=()
    for module in "${SELECTED_MODULES[@]}"; do
        contains "$module" "${SKIP_MODULES[@]}" || filtered_modules+=("$module")
    done
    SELECTED_MODULES=("${filtered_modules[@]}")
fi

[[ ${#SELECTED_MODULES[@]} -gt 0 ]] || die "No modules are selected."

echo
echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}     BadAssKali Bootstrap${NC}"
echo -e "${BLUE}==================================${NC}"
echo

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    die "Do not run install.sh with sudo; run it as your normal user."
fi

[[ -d "$ROOT_DIR/modules" ]] || die "modules directory not found."

echo "Profile: $PROFILE"
echo "Selected modules:"
printf '  - %s\n' "${SELECTED_MODULES[@]}"
echo

if $DRY_RUN; then
    log "Dry run complete; no files or packages were changed."
    if contains "07-ghostty.sh" "${SELECTED_MODULES[@]}"; then
        echo "Ghostty: method=$GHOSTTY_METHOD prefix=$GHOSTTY_PREFIX channel=$GHOSTTY_CHANNEL version=${GHOSTTY_VERSION:-latest} jobs=${GHOSTTY_BUILD_JOBS:-auto} verify=$GHOSTTY_VERIFY force=$GHOSTTY_FORCE keep-build=$GHOSTTY_KEEP_BUILD"
    fi
    [[ -z "$ADDONS" ]] || echo "Add-ons: $ADDONS"
    exit 0
fi

if ! $ASSUME_YES; then
    read -rp "Continue installation? [Y/n] " confirmation
    confirmation=${confirmation:-Y}
    [[ "$confirmation" =~ ^[Yy]$ ]] || {
        warn "Installation cancelled."
        exit 0
    }
fi

FINISH_ENABLED=true
export BADASSKALI_CONFIG_MODE="$CONFIG_MODE"
export BADASSKALI_OFFLINE="$OFFLINE"
export BADASSKALI_DOWNLOAD_ONLY="$DOWNLOAD_ONLY"
export BADASSKALI_CACHE_DIR="$CACHE_DIR"
BADASSKALI_SNAPSHOT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/badasskali/backups/$(date +%Y%m%d-%H%M%S)-install"
export BADASSKALI_SNAPSHOT_DIR
mkdir -p "$BADASSKALI_SNAPSHOT_DIR/files"
: >"$BADASSKALI_SNAPSHOT_DIR/manifest.tsv"
RUN_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/badasskali/logs/$(date +%Y%m%d-%H%M%S)-install"
mkdir -p "$RUN_LOG_DIR"

for module_name in "${SELECTED_MODULES[@]}"; do
    module_path="$ROOT_DIR/modules/$module_name"

    if [[ ! -f "$module_path" ]]; then
        fail "$module_name not found."
        FAILED+=("$module_name")
        $FAIL_FAST && break
        continue
    fi

    echo
    echo "----------------------------------"
    echo "Running: $module_name"
    echo "----------------------------------"
    echo

    if [[ "$module_name" == "07-ghostty.sh" ]]; then
        module_command=(bash "$module_path" --method "$GHOSTTY_METHOD" --prefix "$GHOSTTY_PREFIX" --channel "$GHOSTTY_CHANNEL")
        [[ -z "$GHOSTTY_VERSION" ]] || module_command+=(--version "$GHOSTTY_VERSION")
        [[ -z "$GHOSTTY_BUILD_JOBS" ]] || module_command+=(--build-jobs "$GHOSTTY_BUILD_JOBS")
        $GHOSTTY_VERIFY || module_command+=(--no-verify)
        $GHOSTTY_ACCEPT_COMMUNITY && module_command+=(--accept-community-binary)
        $GHOSTTY_FORCE && module_command+=(--force)
        $GHOSTTY_KEEP_BUILD && module_command+=(--keep-build)
    else
        module_command=(bash "$module_path")
    fi

    module_log="$RUN_LOG_DIR/${module_name%.sh}.log"
    if "${module_command[@]}" \
        > >(tee "$module_log") \
        2> >(tee -a "$module_log" >&2); then
        log "$module_name completed."
    else
        fail "$module_name failed."
        fail "Detailed log: $module_log"
        FAILED+=("$module_name")
        $FAIL_FAST && break
    fi
done

if [[ -n "$ADDONS" && ${#FAILED[@]} -eq 0 ]]; then
    echo
    log "Installing optional add-ons: $ADDONS"
    if "$ROOT_DIR/badasskali" addons install "$ADDONS"; then
        log "Optional add-ons completed."
    else
        fail "Optional add-on installation failed."
        FAILED+=("addons:$ADDONS")
    fi
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    warn "Some modules failed."
    warn "Run './badasskali doctor' and inspect: $RUN_LOG_DIR"
    exit 1
fi

log "All selected modules completed successfully."
