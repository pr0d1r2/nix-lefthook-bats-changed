#!/usr/bin/env bats

@test "default package carries GNU parallel for bats --jobs" {
    local root="$BATS_TEST_DIRNAME/../.."
    local package_path
    package_path="$(nix build --no-link --print-out-paths "$root#default")"

    local references
    references="$(nix-store -q --references "$package_path")"
    [[ "$references" == *-parallel-* ]]
}
