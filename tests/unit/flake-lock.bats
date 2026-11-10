#!/usr/bin/env bats

@test "locked nixpkgs supplies fixed ruby and brotli versions" {
    local root="$BATS_TEST_DIRNAME/../.."
    local ruby brotli

    ruby="$(nix eval --raw --impure --expr "let f = builtins.getFlake \"$root\"; pkgs = import f.inputs.nixpkgs {}; in pkgs.ruby.version")"
    brotli="$(nix eval --raw --impure --expr "let f = builtins.getFlake \"$root\"; pkgs = import f.inputs.nixpkgs {}; in pkgs.brotli.version")"

    version_at_least() {
        [ "$(printf '%s\n' "$1" "$2" | LC_ALL=C sort -V | head -n1)" = "$2" ]
    }

    version_at_least "$ruby" "3.4.12"
    version_at_least "$brotli" "1.2.1"
}
