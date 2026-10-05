#!/usr/bin/env bash

BAK_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/badasskali"
BAK_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/badasskali"

state_init() {
    mkdir -p "$BAK_STATE_HOME/backups" "$BAK_CONFIG_HOME"
}

snapshot_begin() {
    state_init
    local label="${1:-manual}"
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    BADASSKALI_SNAPSHOT_DIR="$BAK_STATE_HOME/backups/${stamp}-${label}"
    mkdir -p "$BADASSKALI_SNAPSHOT_DIR/files"
    : >"$BADASSKALI_SNAPSHOT_DIR/manifest.tsv"
    export BADASSKALI_SNAPSHOT_DIR
    printf '%s\n' "$BADASSKALI_SNAPSHOT_DIR"
}

snapshot_ensure() {
    if [[ -z "${BADASSKALI_SNAPSHOT_DIR:-}" ]]; then
        snapshot_begin "${1:-automatic}" >/dev/null
    fi
}

backup_path() {
    local target="$1"
    snapshot_ensure automatic

    local normalized="${target#/}"
    local destination="$BADASSKALI_SNAPSHOT_DIR/files/$normalized"
    mkdir -p "$(dirname "$destination")"

    if [[ -e "$target" || -L "$target" ]]; then
        cp -a -- "$target" "$destination"
        printf 'present\t%s\n' "$target" >>"$BADASSKALI_SNAPSHOT_DIR/manifest.tsv"
    else
        printf 'absent\t%s\n' "$target" >>"$BADASSKALI_SNAPSHOT_DIR/manifest.tsv"
    fi
}

latest_snapshot() {
    local latest=""
    [[ -d "$BAK_STATE_HOME/backups" ]] || return 1
    latest="$(find "$BAK_STATE_HOME/backups" -mindepth 1 -maxdepth 1 -type d -print |
        sort | tail -n 1)"
    [[ -n "$latest" ]] || return 1
    printf '%s\n' "$latest"
}

list_snapshots() {
    [[ -d "$BAK_STATE_HOME/backups" ]] || return 0
    find "$BAK_STATE_HOME/backups" -mindepth 1 -maxdepth 1 -type d -print |
        sort -r | sed 's#.*/##'
}

restore_snapshot() {
    local snapshot="$1"
    local manifest="$snapshot/manifest.tsv"
    [[ -r "$manifest" ]] || return 1

    while IFS=$'\t' read -r state target; do
        [[ -n "$target" ]] || continue
        local source="$snapshot/files/${target#/}"
        case "$state" in
            present)
                mkdir -p "$(dirname "$target")"
                if [[ -d "$target" && ! -L "$target" ]]; then
                    rm -rf -- "$target"
                else
                    rm -f -- "$target"
                fi
                cp -a -- "$source" "$target"
                ;;
            absent)
                if [[ -d "$target" && ! -L "$target" ]]; then
                    rm -rf -- "$target"
                else
                    rm -f -- "$target"
                fi
                ;;
        esac
    done <"$manifest"
}

replace_managed_block() {
    local target="$1"
    local block_name="$2"
    local content_file="$3"
    local comment="${4:-#}"
    local begin="${comment} >>> BADASSKALI:${block_name} >>>"
    local end="${comment} <<< BADASSKALI:${block_name} <<<"
    local temporary

    snapshot_ensure config
    backup_path "$target"
    mkdir -p "$(dirname "$target")"
    temporary="$(mktemp -t badasskali-config.XXXXXX)"

    if [[ -r "$target" ]]; then
        awk -v begin="$begin" -v end="$end" '
            $0 == begin { skipping=1; next }
            $0 == end { skipping=0; next }
            !skipping { print }
        ' "$target" >"$temporary"
    fi

    {
        printf '\n%s\n' "$begin"
        cat "$content_file"
        printf '%s\n' "$end"
    } >>"$temporary"

    install -m 0644 "$temporary" "$target"
    rm -f -- "$temporary"
}
