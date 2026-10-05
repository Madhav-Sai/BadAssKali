#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/badasskali-test.XXXXXX")"
    export HOME="$TEST_HOME"
    export BADASSKALI_SNAPSHOT_DIR="$TEST_HOME/state/install"
    mkdir -p "$HOME/.config/ghostty"
}

teardown() {
    rm -rf -- "$TEST_HOME"
}

@test "configuration merge preserves existing content" {
    printf 'export KEEP_ME=yes\n' > "$HOME/.zshrc"
    printf '# custom ghostty\n' > "$HOME/.config/ghostty/config"

    run bash "$REPO_ROOT/modules/04-p10k.sh"
    [ "$status" -eq 0 ]
    run bash "$REPO_ROOT/modules/13-configs.sh"
    [ "$status" -eq 0 ]

    grep -Fq 'export KEEP_ME=yes' "$HOME/.zshrc"
    grep -Fq '# custom ghostty' "$HOME/.config/ghostty/config"
    [ "$(grep -Fc '# >>> BADASSKALI:shell >>>' "$HOME/.zshrc")" -eq 1 ]
}

@test "alias installation is idempotent and preserves user aliases" {
    printf "alias mine='echo mine'\n" > "$HOME/.aliases"
    run bash "$REPO_ROOT/modules/12-pentest.sh"
    [ "$status" -eq 0 ]
    run bash "$REPO_ROOT/modules/12-pentest.sh"
    [ "$status" -eq 0 ]

    grep -Fq "alias mine='echo mine'" "$HOME/.aliases"
    [ "$(grep -Fc '# BADASSKALI_ALIASES' "$HOME/.aliases")" -eq 1 ]
}

@test "backup and rollback restore managed files" {
    printf 'before\n' > "$HOME/.zshrc"
    run "$REPO_ROOT/badasskali" backup
    [ "$status" -eq 0 ]
    printf 'after\n' > "$HOME/.zshrc"

    run "$REPO_ROOT/badasskali" rollback --yes
    [ "$status" -eq 0 ]
    grep -Fxq before "$HOME/.zshrc"
}

@test "selective uninstall removes managed blocks but keeps user content" {
    printf 'export KEEP_ME=yes\n' > "$HOME/.zshrc"
    run bash "$REPO_ROOT/modules/04-p10k.sh"
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/uninstall.sh" --only configs --yes
    [ "$status" -eq 0 ]
    grep -Fq 'export KEEP_ME=yes' "$HOME/.zshrc"
    ! grep -Fq '# >>> BADASSKALI:shell >>>' "$HOME/.zshrc"
}

@test "terminal config fixes tmux, vim, and nano" {
    run bash "$REPO_ROOT/modules/04-p10k.sh"
    run bash "$REPO_ROOT/modules/13-configs.sh"
    [ "$status" -eq 0 ]

    grep -Fq 'default-terminal "tmux-256color"' "$HOME/.tmux.conf"
    grep -Fq 'set nocompatible' "$HOME/.vimrc"
    grep -Fq 'set mouse' "$HOME/.nanorc"
    grep -Fq 'term = xterm-256color' "$HOME/.config/ghostty/config"
}
