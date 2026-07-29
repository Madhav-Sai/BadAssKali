#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/badasskali-cli.XXXXXX")"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf -- "$TEST_HOME"
}

@test "management help advertises operational commands" {
    run "$REPO_ROOT/badasskali" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"doctor"* ]]
    [[ "$output" == *"rollback"* ]]
    [[ "$output" == *"addons"* ]]
}

@test "alias packs can be enabled and disabled" {
    run "$REPO_ROOT/badasskali" aliases enable web cloud
    [ "$status" -eq 0 ]
    grep -Fxq web "$HOME/.config/badasskali/enabled-alias-packs"
    grep -Fxq cloud "$HOME/.config/badasskali/enabled-alias-packs"

    run "$REPO_ROOT/badasskali" aliases disable cloud
    [ "$status" -eq 0 ]
    grep -Fxq web "$HOME/.config/badasskali/enabled-alias-packs"
    ! grep -Fxq cloud "$HOME/.config/badasskali/enabled-alias-packs"
}

@test "themes apply through managed blocks" {
    run "$REPO_ROOT/badasskali" theme apply tokyo-night
    [ "$status" -eq 0 ]
    grep -Fq 'background = #1a1b26' "$HOME/.config/ghostty/config"
    grep -Fq '# >>> BADASSKALI:theme >>>' "$HOME/.tmux.conf"
}

@test "uninstaller dry-run does not change files" {
    printf 'keep\n' > "$HOME/.zshrc"
    run "$REPO_ROOT/uninstall.sh" --only configs --dry-run
    [ "$status" -eq 0 ]
    grep -Fxq keep "$HOME/.zshrc"
}

@test "doctor JSON remains machine readable when issues are found" {
    run "$REPO_ROOT/badasskali" doctor --json
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    [[ "$output" == \{\"healthy\":* ]]
    [[ "$output" == *'"issues":['* ]]
}
