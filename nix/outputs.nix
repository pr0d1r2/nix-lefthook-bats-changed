{
  self,
  nixpkgs,
  set-and-setting,
  nix-lefthook-bats-failures-only-src,
  ...
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
  fragments = [
    "base"
    "nix"
    "shell"
    "ascii"
    "markdown"
    "yaml"
  ];
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
      };
    setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
  });

  devShells = forAllSystems (
    pkgs:
    let
      mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
      sys = pkgs.stdenv.hostPlatform.system;
    in
    set-and-setting.lib.mkDevShells {
      inherit pkgs;
      basePackages = mat.packages ++ [ self.packages.${sys}.default ];
      settingHook = ''
        ${self.packages.${sys}.setting}/bin/sync-setting .
        _assemble_out="$(mktemp -d)"
        FRAGMENTS="${builtins.concatStringsSep " " fragments}" \
          out="$_assemble_out" \
          FRAGMENTS_DIR="${set-and-setting}/setting/integrations/lefthook" \
          bash "${set-and-setting}/setting/lib/assemble-lefthook.sh"
        cp -f "$_assemble_out/lefthook.yml" lefthook.yml
        rm -rf "$_assemble_out"
      '';
    }
  );

  checks = forAllSystems (
    pkgs:
    (set-and-setting.lib.checksFor {
      inherit pkgs fragments;
      src = ../.;
    })
    // {
      dep-graph = set-and-setting.lib.mkDepGraphCheck {
        inherit pkgs;
        projectRoot = ../.;
      };
      default = pkgs.runCommand "checks" { } "touch $out";
    }
  );

  apps = forAllSystems (
    pkgs:
    let
      mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
      sys = pkgs.stdenv.hostPlatform.system;
    in
    {
      confirm = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "confirm";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.diffutils
              pkgs.findutils
              pkgs.gawk
              pkgs.git
              pkgs.gnugrep
            ]
            ++ mat.packages
            ++ [ self.packages.${sys}.default ];
            text =
              builtins.replaceStrings
                [
                  "@FRAGMENTS_DIR@"
                  "@ASSEMBLE_SCRIPT@"
                  "@DETECT_SCRIPT@"
                  "@SETTING_SRC@"
                  "@CONFIRM_SCRIPT@"
                  "@CONFIRM_REV@"
                ]
                [
                  "${set-and-setting}/setting/integrations/lefthook"
                  "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                  "${set-and-setting}/setting/lib/detect-fragments.sh"
                  "${self.packages.${sys}.setting}"
                  "${set-and-setting}/lib/confirm.sh"
                  "${set-and-setting.rev or "unknown"}"
                ]
                (builtins.readFile ./confirm-wrapper.sh);
          }
        }/bin/confirm";
      };
    }
  );
}
