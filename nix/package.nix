{
  pkgs,
  nix-lefthook-bats-failures-only-src,
}:
let
  batsWithLibs = pkgs.bats.withLibraries (p: [
    p.bats-assert
    p.bats-support
    p.bats-file
  ]);
  findBatsForFile = pkgs.writeText "find-bats-for-file.sh" (
    builtins.readFile ../find-bats-for-file.sh
  );
  lefthook-bats-failures-only = pkgs.writeShellApplication {
    name = "lefthook-bats-failures-only";
    runtimeInputs = [ batsWithLibs ];
    text = builtins.readFile "${nix-lefthook-bats-failures-only-src}/lefthook-bats-failures-only.sh";
  };
in
pkgs.writeShellApplication {
  name = "lefthook-bats-changed";
  runtimeInputs = [
    batsWithLibs
    pkgs.gawk
    pkgs.coreutils
    lefthook-bats-failures-only
  ];
  text = builtins.replaceStrings [ "@FIND_BATS_FOR_FILE@" ] [ "${findBatsForFile}" ] (
    builtins.readFile ../lefthook-bats-changed.sh
  );
}
