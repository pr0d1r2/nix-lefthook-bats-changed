#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}

@test "shared CI workflow is pinned to a full commit SHA" {
    local workflow="$BATS_TEST_DIRNAME/../../.github/workflows/ci.yml"
    run sed -n 's|.*uses: .*/guardrails.yml@||p' "$workflow"
    assert_success
    [[ "$output" =~ ^[0-9a-f]{40}$ ]]
}
