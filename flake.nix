{
  description = "Lefthook-compatible bats changed-files runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-lefthook-nixfmt = {
      url = "github:pr0d1r2/nix-lefthook-nixfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-shellcheck = {
      url = "github:pr0d1r2/nix-lefthook-shellcheck";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-shfmt = {
      url = "github:pr0d1r2/nix-lefthook-shfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-statix = {
      url = "github:pr0d1r2/nix-lefthook-statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-deadnix = {
      url = "github:pr0d1r2/nix-lefthook-deadnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-nix-no-embedded-shell = {
      url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-bats-failures-only = {
      url = "github:pr0d1r2/nix-lefthook-bats-failures-only";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-lefthook-nixfmt,
      nix-lefthook-shellcheck,
      nix-lefthook-shfmt,
      nix-lefthook-statix,
      nix-lefthook-deadnix,
      nix-lefthook-nix-no-embedded-shell,
      nix-lefthook-bats-failures-only,
    }:
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
        default = pkgs.writeShellApplication {
          name = "lefthook-bats-changed";
          runtimeInputs = [
            pkgs.bats
            pkgs.gawk
            pkgs.coreutils
            nix-lefthook-bats-failures-only.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
          text = builtins.readFile ./lefthook-bats-changed.sh;
        };
      });

      devShells = forAllSystems (
        pkgs:
        let
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
            p.bats-file
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-nixfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-shellcheck.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-shfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-statix.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-deadnix.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-nix-no-embedded-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
              batsWithLibs
              pkgs.yamllint
              pkgs.git
              pkgs.lefthook
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        }
      );
    };
}
