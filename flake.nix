{
  description = "Lefthook-compatible bats changed-files runner";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-bats-failures-only-src = {
      url = "github:pr0d1r2/nix-lefthook-bats-failures-only";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-dev-shell-agentic,
      nix-lefthook-bats-failures-only-src,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default =
          let
            batsWithLibs = pkgs.bats.withLibraries (p: [
              p.bats-assert
              p.bats-support
              p.bats-file
            ]);
            findBatsForFile = pkgs.writeText "find-bats-for-file.sh" (
              builtins.readFile ./find-bats-for-file.sh
            );
          in
          pkgs.writeShellApplication {
            name = "lefthook-bats-changed";
            runtimeInputs = [
              batsWithLibs
              pkgs.gawk
              pkgs.coreutils
              (pkgs.writeShellApplication {
                name = "lefthook-bats-failures-only";
                runtimeInputs = [
                  batsWithLibs
                ];
                text = builtins.readFile "${nix-lefthook-bats-failures-only-src}/lefthook-bats-failures-only.sh";
              })
            ];
            text = builtins.replaceStrings [ "@FIND_BATS_FOR_FILE@" ] [ "${findBatsForFile}" ] (
              builtins.readFile ./lefthook-bats-changed.sh
            );
          };
      });

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          shells = nix-dev-shell-agentic.lib.mkShells {
            inherit pkgs inputs;
            ciPackages = [
              self.packages.${system}.default
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${shells.batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        in
        shells
      );
    };
}
