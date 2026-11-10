#!/usr/bin/env bats

@test "shared CI workflow is pinned to a full commit SHA" {
    local workflow="$BATS_TEST_DIRNAME/../../.github/workflows/ci.yml"
    run sed -n 's|.*uses: .*/guardrails.yml@||p' "$workflow"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9a-f]{40}$ ]]
}
