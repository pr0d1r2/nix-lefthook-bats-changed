#!/usr/bin/env bats

@test "locked nixpkgs supplies fixed ruby and brotli versions" {
    local root="$BATS_TEST_DIRNAME/../.."
    local versions ruby brotli

    versions="$(nix eval --raw --impure --expr "let
        lock = builtins.fromJSON (builtins.readFile \"$root/flake.lock\");
        nixpkgs = builtins.filter
            (node: (node.locked.owner or \"\") == \"NixOS\" && (node.locked.repo or \"\") == \"nixpkgs\")
            (builtins.attrValues lock.nodes);
    in builtins.concatStringsSep \"\\n\" (builtins.map (node: let
        pkgs = import (builtins.fetchTree node.locked) {};
    in builtins.concatStringsSep \" \" [ pkgs.ruby.version pkgs.brotli.version ]) nixpkgs)")"

    version_at_least() {
        [ "$(printf '%s\n' "$1" "$2" | LC_ALL=C sort -V | head -n1)" = "$2" ]
    }

    while read -r ruby brotli; do
        version_at_least "$ruby" "3.4.12"
        version_at_least "$brotli" "1.2.1"
    done <<< "$versions"
}
