# SPEC — Flatten nix-lefthook-bats-changed (drop nix-dev-shell-agentic)

## Goal
Remove the `nix-dev-shell-agentic` flake input (and its near-cyclic dependency
tree) from `flake.nix`, replacing the devShell construction with an inline
`pkgs.mkShell` build. Mirror the proven `nix-lefthook-statix` flattened template
("siblings-in-remotes" rule). Preserve EVERY current output verbatim.

## Preserved verbatim (no behavior change)
- `packages.<system>.default` = `lefthook-bats-changed`:
  - `runtimeInputs`: `batsWithLibs` (bats + bats-assert/support/file), `gawk`,
    `coreutils`, and a NESTED `lefthook-bats-failures-only` built from the
    `flake = false` `nix-lefthook-bats-failures-only-src` input (runtimeInputs
    `batsWithLibs`).
  - `text`: `lefthook-bats-changed.sh` with `@FIND_BATS_FOR_FILE@` replaced by
    the in-repo `./find-bats-for-file.sh` (via `writeText`).
  - This whole block is copied unchanged.
- `devShells.<system>.{default,ci}` keep the same effective contents the
  agentic `mkShells` produced: the repo's own package + lefthook + the lint-hook
  wrapper binaries the repo's `lefthook.yml` remotes invoke + base CI tools +
  `batsWithLibs`. `BATS_LIB_PATH` on `ci`; `dev.sh` shellHook on `default`.

## Input changes
REMOVE:
- `nix-dev-shell-agentic` (heavy flake input — root of the explosion).

ADD (all `flake = false` source leaves, siblings invoked by lefthook.yml
remotes; companions read via `${src}/<name>.sh`):
- `nix-lefthook-deadnix-src`
- `nix-lefthook-editorconfig-checker-src`
- `nix-lefthook-file-size-check-src` (provides `get-file-size-limit` +
  `lefthook-file-size-check`)
- `nix-lefthook-git-conflict-markers-src`
- `nix-lefthook-git-no-local-paths-src`
- `nix-lefthook-missing-final-newline-src`
- `nix-lefthook-nixfmt-src`
- `nix-lefthook-nix-no-embedded-shell-src`
- `nix-lefthook-shellcheck-src`
- `nix-lefthook-shfmt-src`
- `nix-lefthook-statix-src`
- `nix-lefthook-trailing-whitespace-src`
- `nix-lefthook-typos-src`
- `nix-lefthook-yamllint-src`
- `nix-lefthook-bats-unit-src`

KEEP (already present, `flake = false`):
- `nix-lefthook-bats-failures-only-src`

KEEP: `nixpkgs-lock`, `nixpkgs` (follows `nixpkgs-lock/nixpkgs`).

Final real flake inputs: `nixpkgs-lock` + `nixpkgs` follow; everything else is a
`flake = false` source leaf. The cycle never enters the graph.

## devShell rebuild (inline, mirrors statix template)
- `wrap = name: src: extra: pkgs.writeShellApplication ({ inherit name; text =
  builtins.readFile "${src}/${name}.sh"; } // extra);`
- `lefthookWrappersFor pkgs` = the wrapper list (one per lint hook above),
  including the nested `get-file-size-limit` form for file-size-check and the
  SCANNER-env form for nix-no-embedded-shell (verbatim from agentic source).
- `ciCommon` = `[ self.packages.<system>.default batsWithLibs pkgs.bats
  pkgs.coreutils pkgs.git pkgs.lefthook pkgs.nix pkgs.parallel ] ++
  lefthookWrappersFor pkgs`.
- `ci  = mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }`
- `default = mkShell { packages = ciCommon; shellHook = <dev.sh with
  @BATS_LIB_PATH@ replaced by batsWithLibs>; }`

## Non-goals / anti-bloat
- No vendoring of external files. Companions already in this repo
  (`find-bats-for-file.sh`) stay as `readFile ./...`. Hook companions are read
  from their `flake = false` `-src` leaf.
- `config/lefthook/file_size_limits.yml`: bump `nix` limit to 10240 ONLY if the
  enlarged flake.nix trips the file-size hook.
- `shfmt -i2 -ci` reformat of touched shell only if the hook requires it.

## Gate (must pass before push)
1. `nix flake check` green.
2. `nix flake show` lists the same packages (`default`) and devShells
    (`default`, `ci`) for all 4 systems.
3. `lefthook run pre-commit --all-files` passes inside `nix develop` (no
    `--no-verify`).
4. `jq '.nodes|keys|length' flake.lock` drops substantially.

Only then: branch `flatten-drop-agentic`, commit, push, open DRAFT PR.
