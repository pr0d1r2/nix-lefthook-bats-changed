{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";
    set-and-setting.inputs.nixpkgs-lock.follows = "nixpkgs-lock";

    nix-lefthook-bats-failures-only-src.url = "github:pr0d1r2/nix-lefthook-bats-failures-only";
    nix-lefthook-bats-failures-only-src.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      nix-lefthook-bats-failures-only-src,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      src = ./.;
    }
    // (import ./nix/outputs.nix {
      inherit
        self
        nixpkgs
        set-and-setting
        nix-lefthook-bats-failures-only-src
        ;
    });
}
