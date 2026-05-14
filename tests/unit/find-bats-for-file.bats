#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$(mktemp -d)"
    SCRIPT="$BATS_TEST_DIRNAME/../../find-bats-for-file.sh"
}

teardown() {
    rm -rf "$TMP"
}

@test "script file exists" {
    [ -f "$SCRIPT" ]
}

@test "top-level script maps to tests/unit/<stem>.bats" {
    cd "$TMP"
    mkdir -p tests/unit
    echo '@test "x" { true; }' > tests/unit/my-tool.bats
    echo "" > my-tool.sh
    run bash "$SCRIPT" my-tool.sh
    assert_success
    assert_output "tests/unit/my-tool.bats"
}

@test "nested script maps to tests/unit/<dir>/<stem>.bats" {
    cd "$TMP"
    mkdir -p scripts/build tests/unit/scripts/build
    echo "" > scripts/build/deploy.sh
    echo '@test "x" { true; }' > tests/unit/scripts/build/deploy.bats
    run bash "$SCRIPT" scripts/build/deploy.sh
    assert_success
    assert_output "tests/unit/scripts/build/deploy.bats"
}

@test "normalizes underscores to hyphens" {
    cd "$TMP"
    mkdir -p tests/unit
    echo "" > my_tool.sh
    echo '@test "x" { true; }' > tests/unit/my-tool.bats
    run bash "$SCRIPT" my_tool.sh
    assert_success
    assert_output "tests/unit/my-tool.bats"
}

@test "falls back to underscore name when hyphen not found" {
    cd "$TMP"
    mkdir -p tests/unit
    echo "" > my_tool.sh
    echo '@test "x" { true; }' > tests/unit/my_tool.bats
    run bash "$SCRIPT" my_tool.sh
    assert_success
    assert_output "tests/unit/my_tool.bats"
}

@test "prints nothing when no matching bats exists" {
    cd "$TMP"
    mkdir -p tests/unit
    echo "" > orphan.sh
    run bash "$SCRIPT" orphan.sh
    assert_success
    assert_output ""
}
