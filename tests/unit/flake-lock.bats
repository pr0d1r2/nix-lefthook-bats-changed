#!/usr/bin/env bats

@test "locked nixpkgs supplies fixed ruby and brotli versions" {
    local root="$BATS_TEST_DIRNAME/../.."
    local ruby brotli

    ruby="$(nix eval --raw --impure --expr "let f = builtins.getFlake \"$root\"; pkgs = import f.inputs.nixpkgs {}; in pkgs.ruby.version")"
    brotli="$(nix eval --raw --impure --expr "let f = builtins.getFlake \"$root\"; pkgs = import f.inputs.nixpkgs {}; in pkgs.brotli.version")"

    [ "$ruby" = "3.4.12" ]
    [ "$brotli" = "1.2.1" ]
}
