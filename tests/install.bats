#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "installer exposes profiles, modules, add-ons, and Ghostty controls" {
    run "$REPO_ROOT/install.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--profile core"* ]]
    [[ "$output" == *"--addons LIST"* ]]
    [[ "$output" == *"--ghostty-channel C"* ]]
}

@test "module selection trims spaces and removes duplicates" {
    run "$REPO_ROOT/install.sh" --only "07, 12,07" --dry-run
    [ "$status" -eq 0 ]
    [ "$(grep -c '  - 07-ghostty.sh' <<< "$output")" -eq 1 ]
    [ "$(grep -c '  - 12-pentest.sh' <<< "$output")" -eq 1 ]
}

@test "core profile includes the management CLI" {
    run "$REPO_ROOT/install.sh" --profile core --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"16-management.sh"* ]]
    [[ "$output" != *"15-security-tools.sh"* ]]
}

@test "pentest profile includes modern recon and workspace modules" {
    run "$REPO_ROOT/install.sh" --profile pentest --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"17-projectdiscovery.sh"* ]]
    [[ "$output" == *"18-autorecon.sh"* ]]
    [[ "$output" == *"19-engagement-workspace.sh"* ]]
    [[ "$output" == *"20-recon-workflow.sh"* ]]
}

@test "terminal profile does not silently install pentest workflow modules" {
    run "$REPO_ROOT/install.sh" --profile terminal --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"17-projectdiscovery.sh"* ]]
    [[ "$output" != *"18-autorecon.sh"* ]]
}

@test "platform detection recognizes Parrot as a Debian security distro" {
    fixture="$BATS_TEST_TMPDIR/os-release"
    cat >"$fixture" <<'EOF'
ID=parrot
ID_LIKE=debian
VERSION_ID=7.0
PRETTY_NAME="Parrot Security 7"
EOF
    run env BADASSKALI_OS_RELEASE="$fixture" bash -c \
        'source "$1/lib/platform.sh"; detect_platform; printf "%s:%s:%s" "$BAK_OS_ID" "$BAK_PACKAGE_FAMILY" "$BAK_SECURITY_DISTRO"' \
        _ "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ "$output" = "parrot:debian:parrot" ]
}

@test "engagement workflow enforces selected scope before running tools" {
    test_home="$BATS_TEST_TMPDIR/home"
    mkdir -p "$test_home"
    run env HOME="$test_home" XDG_STATE_HOME="$test_home/state" \
        bash "$REPO_ROOT/modules/19-engagement-workspace.sh"
    [ "$status" -eq 0 ]
    run env HOME="$test_home" XDG_STATE_HOME="$test_home/state" \
        "$test_home/.local/bin/bak-engage" new demo --scope example.com --authorized
    [ "$status" -eq 0 ]
    run env HOME="$test_home" XDG_STATE_HOME="$test_home/state" \
        bash "$REPO_ROOT/modules/20-recon-workflow.sh"
    [ "$status" -eq 0 ]
    run env HOME="$test_home" XDG_STATE_HOME="$test_home/state" \
        "$test_home/.local/bin/bak-recon" discover outside.test --i-have-authorization
    [ "$status" -eq 1 ]
    [[ "$output" == *"outside the selected engagement scope"* ]]
}

@test "recon help works before an engagement exists" {
    run bash "$REPO_ROOT/configs/bin/bak-recon" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Scope-aware reconnaissance workflow"* ]]
}

@test "invalid Ghostty controls are rejected" {
    run "$REPO_ROOT/install.sh" --only 07 --ghostty-channel unstable --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid Ghostty channel"* ]]
}

@test "download-only narrows execution to package caching" {
    run "$REPO_ROOT/install.sh" --profile terminal --addons developer --download-only --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"01-packages.sh"* ]]
    [[ "$output" != *"07-ghostty.sh"* ]]
    [[ "$output" == *"Add-ons: developer"* ]]
}
