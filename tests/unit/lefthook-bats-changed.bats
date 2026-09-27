#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    load "${BATS_LIB_PATH}/bats-file/load.bash"

    # The standard's dev shell does not carry this repo's own package, so
    # exercise the working-tree script (placeholder resolved the way
    # packages.default resolves it) under writeShellApplication's strict mode.
    local root="$BATS_TEST_DIRNAME/../.."
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    sed "s|@FIND_BATS_FOR_FILE@|$root/find-bats-for-file.sh|" \
        "$root/lefthook-bats-changed.sh" >"$BATS_TEST_TMPDIR/lefthook-bats-changed.sh"
    printf '#!/usr/bin/env bash\nexec bash -euo pipefail "%s" "$@"\n' \
        "$BATS_TEST_TMPDIR/lefthook-bats-changed.sh" >"$BATS_TEST_TMPDIR/bin/lefthook-bats-changed"
    chmod +x "$BATS_TEST_TMPDIR/bin/lefthook-bats-changed"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    TMP_REPO="$(mktemp -d)"
    mkdir -p "$TMP_REPO/scripts/foo" "$TMP_REPO/tests/unit"
}

teardown() {
    rm -rf "$TMP_REPO"
}

@test "no args exits 0" {
    cd "$TMP_REPO"
    run lefthook-bats-changed
    assert_success
    [ -z "$output" ]
}

@test "non-existent files are ignored" {
    cd "$TMP_REPO"
    run lefthook-bats-changed scripts/foo/gone.sh
    assert_success
}

@test "impl file with no matching spec warns and exits 0" {
    cd "$TMP_REPO"
    : > scripts/foo/widget.sh
    run lefthook-bats-changed scripts/foo/widget.sh
    assert_success
    assert_output --partial "WARN"
    assert_output --partial "scripts/foo/widget.sh"
}

@test "impl file with matching spec runs bats on it" {
    cd "$TMP_REPO"
    mkdir -p tests/unit/scripts/foo
    : > scripts/foo/widget.sh
    cat > tests/unit/scripts/foo/widget.bats <<'BATS'
#!/usr/bin/env bats
@test "placeholder" { true; }
BATS
    run lefthook-bats-changed scripts/foo/widget.sh
    assert_success
    assert_output --partial "running 1 spec(s)"
}

@test "top-level script maps to tests/unit/<stem>.bats" {
    cd "$TMP_REPO"
    : > build.sh
    cat > tests/unit/build.bats <<'BATS'
#!/usr/bin/env bats
@test "placeholder" { true; }
BATS
    run lefthook-bats-changed build.sh
    assert_success
    assert_output --partial "running 1 spec(s)"
}

@test "staged .bats file runs directly" {
    cd "$TMP_REPO"
    cat > tests/unit/foo-widget.bats <<'BATS'
#!/usr/bin/env bats
@test "placeholder" { true; }
BATS
    run lefthook-bats-changed tests/unit/foo-widget.bats
    assert_success
    assert_output --partial "running 1 spec(s)"
}

@test "non-impl non-spec paths are silently skipped" {
    cd "$TMP_REPO"
    : > README.md
    : > config.yml
    run lefthook-bats-changed README.md config.yml
    assert_success
    [ -z "$output" ]
}
