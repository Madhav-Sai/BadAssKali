#!/usr/bin/env bash

set -Eeuo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
fail() {
    echo -e "${RED}[-]${NC} $1"
    exit 1
}

METHOD="auto"
PREFIX_MODE="user"
REQUESTED_VERSION=""
CHANNEL="stable"
BUILD_JOBS=""
VERIFY_DOWNLOADS=true
ACCEPT_COMMUNITY_BINARY=false
FORCE=false
KEEP_BUILD=false
work_dir=""

usage() {
    cat <<'EOF'
Install Ghostty on a supported Linux system.

Usage: bash modules/07-ghostty.sh [options]

  --method METHOD               auto, package, source, snap, or appimage
  --prefix user|system          Source install prefix: ~/.local or /usr
  --version X.Y.Z               Build a specific stable Ghostty version
  --channel stable|tip          Stable releases or upstream prerelease source
  --build-jobs N                Limit parallel Zig build jobs
  --no-verify                   Explicitly skip signature/checksum verification
  --accept-community-binary     Accept AppImage's documented third-party trust
  --uninstall                   Remove a user, Snap, or distro installation
  --force                       Reinstall even when Ghostty already exists
  --keep-build                  Keep downloaded/build files for troubleshooting
  -h, --help                    Show this help

Auto uses an official distro package where available (currently Arch-family),
then falls back to Ghostty's signed official source archive.
EOF
}

cleanup() {
    if $KEEP_BUILD && [[ -n "$work_dir" && -d "$work_dir" ]]; then
        info "Build files kept at: $work_dir"
    elif [[ -n "$work_dir" && -d "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --method)
            [[ $# -ge 2 ]] || fail "--method requires auto, package, or source."
            METHOD="$2"
            shift 2
            ;;
        --prefix)
            [[ $# -ge 2 ]] || fail "--prefix requires user or system."
            PREFIX_MODE="$2"
            shift 2
            ;;
        --version)
            [[ $# -ge 2 ]] || fail "--version requires X.Y.Z."
            REQUESTED_VERSION="$2"
            shift 2
            ;;
        --channel)
            [[ $# -ge 2 ]] || fail "--channel requires stable or tip."
            CHANNEL="$2"
            shift 2
            ;;
        --build-jobs)
            [[ $# -ge 2 ]] || fail "--build-jobs requires a positive number."
            BUILD_JOBS="$2"
            shift 2
            ;;
        --no-verify)
            VERIFY_DOWNLOADS=false
            shift
            ;;
        --accept-community-binary)
            ACCEPT_COMMUNITY_BINARY=true
            shift
            ;;
        --uninstall)
            METHOD="uninstall"
            FORCE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --keep-build)
            KEEP_BUILD=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
done

[[ "$METHOD" =~ ^(auto|package|source|snap|appimage|uninstall)$ ]] || fail "Invalid method: $METHOD"
[[ "$PREFIX_MODE" =~ ^(user|system)$ ]] || fail "Invalid prefix: $PREFIX_MODE"
[[ "$CHANNEL" =~ ^(stable|tip)$ ]] || fail "Invalid channel: $CHANNEL"
[[ -z "$BUILD_JOBS" || "$BUILD_JOBS" =~ ^[1-9][0-9]*$ ]] || fail "Build jobs must be a positive number."
[[ -z "$REQUESTED_VERSION" || "$REQUESTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail "Version must look like 1.3.1."
[[ "$CHANNEL" == "stable" || -z "$REQUESTED_VERSION" ]] ||
    fail "--version can only be combined with --channel stable."

echo
echo "=================================="
echo "     Ghostty Installation"
echo "=================================="
echo

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    fail "Do not run this module as root. Run it as your normal user."
fi

# Look in the usual install locations too: ~/.local/bin is often missing from PATH here.
existing_ghostty=""
for candidate in "$(command -v ghostty 2>/dev/null || true)" \
    "$HOME/.local/bin/ghostty" /usr/local/bin/ghostty /usr/bin/ghostty; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        existing_ghostty="$candidate"
        break
    fi
done

if [[ -n "$existing_ghostty" ]] && ! $FORCE && [[ "$METHOD" != "uninstall" ]]; then
    warn "Ghostty is already installed at $existing_ghostty; skipping download and build."
    "$existing_ghostty" --version || true
    info "Use --force to reinstall it."
    exit 0
fi

[[ -r /etc/os-release ]] || fail "Unable to detect Linux: /etc/os-release is missing."

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')"
OS_LIKE="${ID_LIKE:-}"
OS_LIKE="$(printf '%s' "$OS_LIKE" | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) zig_arch="x86_64-linux" ;;
    aarch64 | arm64) zig_arch="aarch64-linux" ;;
    *) fail "Unsupported architecture: $ARCH. Supported: x86_64 and aarch64/arm64." ;;
esac

case "$OS_ID" in
    kali | parrot | debian | ubuntu | linuxmint | pop) distro_family="debian" ;;
    arch | endeavouros | manjaro | garuda) distro_family="arch" ;;
    fedora | rhel | centos | rocky | almalinux) distro_family="fedora" ;;
    opensuse* | sles) distro_family="suse" ;;
    *)
        if [[ " $OS_LIKE " == *" debian "* ]]; then
            distro_family="debian"
        elif [[ " $OS_LIKE " == *" arch "* ]]; then
            distro_family="arch"
        elif [[ " $OS_LIKE " == *" fedora "* || " $OS_LIKE " == *" rhel "* ]]; then
            distro_family="fedora"
        elif [[ " $OS_LIKE " == *" suse "* ]]; then
            distro_family="suse"
        else
            fail "Unsupported distribution: ${PRETTY_NAME:-$OS_ID}."
        fi
        ;;
esac

info "Detected system: ${PRETTY_NAME:-$OS_ID} ($ARCH)"

verify_install() {
    local binary=""
    if command -v ghostty >/dev/null 2>&1; then
        binary="$(command -v ghostty)"
    elif [[ -x "$HOME/.local/bin/ghostty" ]]; then
        binary="$HOME/.local/bin/ghostty"
    elif [[ -x /usr/bin/ghostty ]]; then
        binary="/usr/bin/ghostty"
    elif [[ -x /usr/local/bin/ghostty ]]; then
        binary="/usr/local/bin/ghostty"
    fi

    [[ -n "$binary" ]] || return 1
    log "Ghostty installed successfully."
    "$binary" --version || true
    info "Binary: $binary"
}

if [[ "$METHOD" == "uninstall" ]]; then
    if command -v snap >/dev/null 2>&1 && snap list ghostty >/dev/null 2>&1; then
        sudo snap remove ghostty
    fi
    if [[ -x "$HOME/.local/bin/ghostty" ]]; then
        rm -f -- "$HOME/.local/bin/ghostty"
    fi
    case "$distro_family" in
        debian) sudo apt-get remove -y ghostty 2>/dev/null || true ;;
        arch) sudo pacman -Rns --noconfirm ghostty 2>/dev/null || true ;;
    esac
    log "Removed detected Ghostty installations."
    exit 0
fi

if [[ "$METHOD" == "snap" ]]; then
    command -v snap >/dev/null 2>&1 || fail "snap is not installed."
    sudo snap install ghostty --classic
    verify_install || fail "Snap reported success, but Ghostty was not found."
    exit 0
fi

if [[ "$METHOD" == "appimage" ]]; then
    $ACCEPT_COMMUNITY_BINARY ||
        fail "The AppImage is community-built. Re-run with --accept-community-binary after reviewing that trust boundary."
    command -v curl >/dev/null 2>&1 || fail "curl is required."
    command -v jq >/dev/null 2>&1 || fail "jq is required."
    case "$ARCH" in
        x86_64) appimage_arch="x86_64" ;;
        aarch64 | arm64) appimage_arch="aarch64" ;;
    esac
    appimage_json="$(curl -fsSL --retry 3 https://api.github.com/repos/pkgforge-dev/ghostty-appimage/releases/latest)"
    appimage_url="$(jq -r --arg suffix "-${appimage_arch}.AppImage" \
        '.assets[] | select(.name | endswith($suffix)) | .browser_download_url' \
        <<<"$appimage_json" | head -n 1)"
    appimage_digest="$(jq -r --arg suffix "-${appimage_arch}.AppImage" \
        '.assets[] | select(.name | endswith($suffix)) | .digest // empty' \
        <<<"$appimage_json" | head -n 1)"
    [[ -n "$appimage_url" && "$appimage_url" != "null" ]] || fail "No compatible Ghostty AppImage was found."
    appimage_tmp="$(mktemp -t ghostty-appimage.XXXXXX)"
    trap 'rm -f -- "$appimage_tmp"' EXIT
    curl -fL --retry 3 "$appimage_url" -o "$appimage_tmp"
    if $VERIFY_DOWNLOADS; then
        command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required for AppImage verification."
        expected_appimage_sha="${appimage_digest#sha256:}"
        [[ "$expected_appimage_sha" =~ ^[a-fA-F0-9]{64}$ ]] ||
            fail "The AppImage release did not publish a SHA-256 digest."
        printf '%s  %s\n' "$expected_appimage_sha" "$appimage_tmp" |
            sha256sum --check --status || fail "AppImage checksum verification failed."
        log "Verified the AppImage SHA-256 digest."
    else
        warn "AppImage checksum verification was explicitly disabled."
    fi
    if [[ "$PREFIX_MODE" == "user" ]]; then
        mkdir -p "$HOME/.local/bin"
        install -m 0755 "$appimage_tmp" "$HOME/.local/bin/ghostty"
    else
        sudo install -m 0755 "$appimage_tmp" /usr/local/bin/ghostty
    fi
    hash -r 2>/dev/null || true
    verify_install || fail "AppImage installation verification failed."
    exit 0
fi

install_package() {
    case "$distro_family" in
        arch)
            command -v pacman >/dev/null 2>&1 || return 1
            log "Installing Ghostty from the Arch-family package repository..."
            sudo pacman -Syu --needed --noconfirm ghostty || return 1
            ;;
        debian)
            command -v apt-get >/dev/null 2>&1 || return 1
            log "Checking the configured APT repositories for Ghostty..."
            sudo apt-get update || return 1
            if ! apt-cache show ghostty >/dev/null 2>&1; then
                warn "No Ghostty package is available in the configured APT repositories."
                return 1
            fi
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ghostty || return 1
            ;;
    esac

    verify_install
}

if [[ "$METHOD" == "package" ]]; then
    install_package || fail "A Ghostty distro package could not be installed. Try --method source."
    exit 0
fi

if [[ "$METHOD" == "auto" ]]; then
    if install_package; then
        exit 0
    fi
    warn "Falling back to a verified source build."
fi

install_debian_dependencies() {
    local packages=(
        build-essential
        ca-certificates
        curl
        gettext
        jq
        libadwaita-1-dev
        libgtk-4-dev
        libxml2-utils
        pkg-config
        xz-utils
    )
    local available=() package

    log "Installing Ghostty source-build dependencies with APT..."
    sudo apt-get update
    for package in "${packages[@]}"; do
        if apt-cache show "$package" >/dev/null 2>&1; then
            available+=("$package")
        else
            warn "Skipping unavailable Ghostty build dependency: $package"
        fi
    done
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -- "${available[@]}"

    if apt-cache show libgtk4-layer-shell-dev >/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libgtk4-layer-shell-dev
    else
        warn "libgtk4-layer-shell-dev is unavailable; Ghostty will build it from source."
    fi

    if [[ "$ARCH" == "x86_64" ]] && apt-cache show gcc-multilib >/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gcc-multilib ||
            warn "gcc-multilib was unavailable; continuing with the native toolchain."
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y minisign ||
        warn "minisign is unavailable; archive signature verification will be skipped."
}

install_arch_dependencies() {
    local packages=(
        base-devel
        ca-certificates
        curl
        gettext
        gtk4
        gtk4-layer-shell
        jq
        libadwaita
        libxml2
        minisign
        pkgconf
        xz
    )

    log "Installing Ghostty source-build dependencies with pacman..."
    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

install_fedora_dependencies() {
    local packages=(
        gcc gcc-c++ curl gettext gtk4-devel gtk4-layer-shell-devel
        jq libadwaita-devel libxml2 minisign pkgconf-pkg-config xz
    )
    log "Installing Ghostty source-build dependencies with DNF..."
    sudo dnf install -y "${packages[@]}"
}

install_suse_dependencies() {
    local packages=(
        gcc gcc-c++ curl gettext gtk4-devel jq libadwaita-devel
        libxml2-tools minisign pkgconf xz
    )
    log "Installing Ghostty source-build dependencies with zypper..."
    sudo zypper --non-interactive install "${packages[@]}"
}

case "$distro_family" in
    debian)
        command -v apt-get >/dev/null 2>&1 || fail "APT was expected but apt-get was not found."
        install_debian_dependencies
        ;;
    arch)
        command -v pacman >/dev/null 2>&1 || fail "pacman was expected but was not found."
        install_arch_dependencies
        ;;
    fedora)
        command -v dnf >/dev/null 2>&1 || fail "DNF was expected but was not found."
        install_fedora_dependencies
        ;;
    suse)
        command -v zypper >/dev/null 2>&1 || fail "zypper was expected but was not found."
        install_suse_dependencies
        ;;
esac

for required_command in curl jq tar awk sort sha256sum; do
    command -v "$required_command" >/dev/null 2>&1 ||
        fail "Required command is missing after dependency installation: $required_command"
done

work_dir="$(mktemp -d -t badasskali-ghostty.XXXXXX)"
candidate_versions=()

if [[ -n "$REQUESTED_VERSION" ]]; then
    candidate_versions+=("$REQUESTED_VERSION")
else
    log "Finding the latest stable Ghostty release..."

    if release_notes_html="$(curl -fsSL --retry 4 --retry-all-errors \
        --connect-timeout 20 https://ghostty.org/docs/install/release-notes 2>/dev/null)"; then
        while IFS= read -r detected_version; do
            [[ -n "$detected_version" ]] && candidate_versions+=("$detected_version")
        done < <(
            printf '%s' "$release_notes_html" |
                grep -oE '/docs/install/release-notes/[0-9]+-[0-9]+-[0-9]+' |
                sed -E 's#.*/([0-9]+)-([0-9]+)-([0-9]+)#\1.\2.\3#' |
                sort -Vru
        )
    else
        warn "Unable to read Ghostty's release-notes page."
    fi

    if [[ ${#candidate_versions[@]} -eq 0 ]] && command -v git >/dev/null 2>&1; then
        warn "Falling back to stable tags from Ghostty's official Git repository."
        while IFS= read -r detected_version; do
            [[ -n "$detected_version" ]] && candidate_versions+=("$detected_version")
        done < <(
            git ls-remote --tags --refs https://github.com/ghostty-org/ghostty.git 2>/dev/null |
                awk -F/ '{print $3}' |
                grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' |
                sed 's/^v//' |
                sort -Vru
        )
    fi

    candidate_versions+=("1.3.1" "1.3.0" "1.2.3")
fi

mapfile -t candidate_versions < <(
    printf '%s\n' "${candidate_versions[@]}" | awk 'NF && !seen[$0]++' | sort -Vr
)

SOURCE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/badasskali"
version=""
source_archive=""
signature_file=""

if [[ "$CHANNEL" == "tip" ]]; then
    version="tip"
    source_archive="$work_dir/ghostty-source.tar.gz"
    signature_file="${source_archive}.minisig"
    tip_base="https://github.com/ghostty-org/ghostty/releases/download/tip"
    curl -fL --retry 4 --retry-all-errors "$tip_base/ghostty-source.tar.gz" -o "$source_archive"
    curl -fL --retry 3 --retry-all-errors "$tip_base/ghostty-source.tar.gz.minisig" -o "$signature_file"
    tar -tzf "$source_archive" >/dev/null 2>&1 || fail "The Ghostty tip archive is invalid."
fi

for candidate in "${candidate_versions[@]}"; do
    [[ "$CHANNEL" == "stable" ]] || break
    candidate_url="https://release.files.ghostty.org/${candidate}/ghostty-${candidate}.tar.gz"
    candidate_archive="$work_dir/ghostty-${candidate}.tar.gz"
    candidate_signature="${candidate_archive}.minisig"
    info "Trying Ghostty ${candidate}..."

    cached_archive="$SOURCE_CACHE/ghostty-${candidate}.tar.gz"
    if [[ -s "$cached_archive" && -s "$cached_archive.minisig" ]] &&
        tar -tzf "$cached_archive" >/dev/null 2>&1; then
        info "Reusing cached download: $cached_archive"
        cp -f "$cached_archive" "$candidate_archive"
        cp -f "$cached_archive.minisig" "$candidate_signature"
        version="$candidate"
        source_archive="$candidate_archive"
        signature_file="$candidate_signature"
        break
    fi

    if curl -fL --retry 4 --retry-all-errors --connect-timeout 20 \
        "$candidate_url" -o "$candidate_archive" &&
        tar -tzf "$candidate_archive" >/dev/null 2>&1; then
        version="$candidate"
        source_archive="$candidate_archive"
        if curl -fL --retry 3 --retry-all-errors \
            "${candidate_url}.minisig" -o "$candidate_signature"; then
            signature_file="$candidate_signature"
            mkdir -p "$SOURCE_CACHE"
            cp -f "$candidate_archive" "$cached_archive" &&
                cp -f "$candidate_signature" "$cached_archive.minisig" || true
        fi
        break
    fi

    warn "Ghostty ${candidate} was unavailable or was not a valid source archive."
    rm -f -- "$candidate_archive" "$candidate_signature"
done

[[ -n "$version" && -s "$source_archive" ]] ||
    fail "Unable to download a valid Ghostty source tarball."

if ! $VERIFY_DOWNLOADS; then
    warn "Download verification was explicitly disabled."
elif command -v minisign >/dev/null 2>&1; then
    [[ -s "$signature_file" ]] || fail "The official Ghostty signature could not be downloaded."
    minisign -Vm "$source_archive" \
        -P 'RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV' ||
        fail "Ghostty source signature verification failed."
    log "Verified the official Ghostty source signature."
else
    warn "minisign is not installed; relying on HTTPS and archive validation."
fi

log "Selected Ghostty release: ${version}"
tar -xzf "$source_archive" -C "$work_dir"

if [[ "$CHANNEL" == "tip" ]]; then
    archive_root="$(tar -tzf "$source_archive" | head -n 1 | cut -d/ -f1)"
    repo_dir="$work_dir/$archive_root"
else
    repo_dir="$work_dir/ghostty-${version}"
fi
[[ -d "$repo_dir" ]] || fail "Expected source directory not found: $repo_dir"

zig_version="$(awk -F'"' '/minimum_zig_version/ {print $2; exit}' "$repo_dir/build.zig.zon")"
[[ -n "$zig_version" ]] || fail "Unable to determine Ghostty's required Zig version."

zig_root="$HOME/.local/opt"
zig_dir="$zig_root/zig-$zig_version"
zig_bin="$zig_dir/zig"

if [[ ! -x "$zig_bin" ]]; then
    log "Installing Zig $zig_version for the Ghostty build..."
    mkdir -p "$zig_root"

    zig_archive="$work_dir/zig.tar.xz"
    zig_url="https://ziglang.org/download/$zig_version/zig-$zig_arch-$zig_version.tar.xz"
    zig_index="$work_dir/zig-index.json"

    curl --fail --location --retry 3 --retry-delay 2 \
        https://ziglang.org/download/index.json -o "$zig_index"
    expected_sha="$(jq -r --arg version "$zig_version" --arg target "$zig_arch" \
        '.[$version][$target].shasum // empty' "$zig_index")"
    [[ "$expected_sha" =~ ^[a-fA-F0-9]{64}$ ]] ||
        fail "Unable to obtain Zig $zig_version's official SHA-256 checksum."

    curl --fail --location --retry 3 --retry-delay 2 "$zig_url" -o "$zig_archive"
    if $VERIFY_DOWNLOADS; then
        printf '%s  %s\n' "$expected_sha" "$zig_archive" | sha256sum --check --status ||
            fail "Zig archive checksum verification failed."
    else
        warn "Skipping Zig checksum verification by request."
    fi

    tar -xJf "$zig_archive" -C "$work_dir"
    extracted_zig="$work_dir/zig-$zig_arch-$zig_version"
    [[ -x "$extracted_zig/zig" ]] ||
        fail "Downloaded Zig archive did not contain the expected binary."

    rm -rf -- "$zig_dir"
    mv "$extracted_zig" "$zig_dir"
else
    info "Reusing Zig $zig_version from $zig_dir"
fi

build_flags=(-Doptimize=ReleaseFast)
[[ -z "$BUILD_JOBS" ]] || build_flags+=("-j${BUILD_JOBS}")
if ! pkg-config --exists gtk4-layer-shell-0 2>/dev/null; then
    build_flags+=(-fno-sys=gtk4-layer-shell)
    info "Using Ghostty's bundled gtk4-layer-shell build."
fi

if [[ "$PREFIX_MODE" == "user" ]]; then
    install_prefix="$HOME/.local"
    mkdir -p "$install_prefix"
    install_command=("$zig_bin" build -p "$install_prefix" "${build_flags[@]}")
else
    install_prefix="/usr"
    install_command=(sudo env "PATH=$(dirname "$zig_bin"):$PATH"
    "$zig_bin" build -p "$install_prefix" "${build_flags[@]}")
fi

log "Building and installing Ghostty v${version} into $install_prefix..."
info "Source builds are slow (often 10-40 minutes on laptops) and Zig prints little while compiling."
info "A status line is shown every 30s; press Ctrl+C to abort."
cd "$repo_dir"

# Zig reports no real progress here, so show an ESTIMATE: the last measured build
# time on this machine, or a guess from the CPU thread count on the first run.
build_started=$SECONDS
time_file="${XDG_CACHE_HOME:-$HOME/.cache}/badasskali/ghostty-build-seconds"
cpu_threads="$(nproc 2>/dev/null || echo 4)"
expected_seconds="$(cat "$time_file" 2>/dev/null || true)"
[[ "$expected_seconds" =~ ^[0-9]+$ && "$expected_seconds" -gt 0 ]] ||
    expected_seconds=$((4800 / cpu_threads))
(( expected_seconds >= 120 )) || expected_seconds=120
info "Estimated build time: about $((expected_seconds / 60)) min (rough guess, shown as ~%)."

(
    while sleep 30; do
        elapsed=$((SECONDS - build_started))
        percent=$((elapsed * 100 / expected_seconds))
        (( percent <= 99 )) || percent=99
        filled=$((percent / 5))
        bar="$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' "$((20 - filled))" '' | tr ' ' '.')"
        remaining=$((expected_seconds - elapsed))
        if (( remaining > 0 )); then
            eta="~$(((remaining + 59) / 60)) min left"
        else
            eta="taking longer than estimated, still working"
        fi
        printf '%b[*]%b Building Ghostty [%s] ~%d%%  %dm%02ds elapsed, %s (load %s)\n' \
            "$BLUE" "$NC" "$bar" "$percent" $((elapsed / 60)) $((elapsed % 60)) "$eta" \
            "$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo '?')"
    done
) &
heartbeat_pid=$!
trap 'kill "$heartbeat_pid" 2>/dev/null || true; cleanup' EXIT

# --summary new lists build steps as they run; --verbose is intentionally avoided.
"${install_command[@]}" --summary new
kill "$heartbeat_pid" 2>/dev/null || true
wait "$heartbeat_pid" 2>/dev/null || true
trap cleanup EXIT
build_seconds=$((SECONDS - build_started))
mkdir -p "$(dirname "$time_file")"
echo "$build_seconds" >"$time_file" 2>/dev/null || true
log "Ghostty build finished in $((build_seconds / 60))m$((build_seconds % 60))s."

if command -v update-desktop-database >/dev/null 2>&1; then
    desktop_dir="$install_prefix/share/applications"
    [[ -d "$desktop_dir" ]] &&
        update-desktop-database "$desktop_dir" >/dev/null 2>&1 || true
fi

hash -r 2>/dev/null || true
verify_install || fail "Ghostty build completed, but its binary was not found."
info "Add $HOME/.local/bin to your desktop session PATH if the app launcher cannot start a user-local install."
