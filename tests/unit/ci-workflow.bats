#!/usr/bin/env bats

@test "shared CI workflow is pinned to a full commit SHA" {
    local workflow="$BATS_TEST_DIRNAME/../../.github/workflows/ci.yml"
    run awk '
        /^  guardrails:[[:space:]]*$/ { in_guardrails=1; next }
        /^  [^[:space:]][^:]*:/ { in_guardrails=0 }
        in_guardrails && /^[[:space:]]+uses:[[:space:]]/ {
            sub(/^[[:space:]]+uses:[[:space:]]+[^@]+@/, "")
            print
            exit
        }
    ' "$workflow"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9a-f]{40}$ ]]
}
