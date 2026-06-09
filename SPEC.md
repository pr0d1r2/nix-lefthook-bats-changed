# SPEC — nix-lefthook-bats-changed

## §G Goal

Lefthook-compatible changed-files bats runner for TDD. On commit/push,
run only the bats specs matching the staged/pushed files: `.bats` files
run directly, `.sh` files map to their `tests/unit/` spec. Nix flake pkg
that composes a nested `lefthook-bats-failures-only` runner and an in-repo
`find-bats-for-file` path mapper. Opensource-safe: zero credentials, zero
local paths, zero private refs.

## §C Constraints

- C1: Pure bash — no Python/Ruby/etc runtime deps
- C2: Nix flake — `writeShellApplication` pkg, devShells via inline
  `pkgs.mkShell` (flattened: no `nix-dev-shell-agentic`)
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`,
  `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded
  local paths, no private repo refs
- C6: All config via env vars — no config files beyond baseline lint config
- C7: Selection-only dispatcher — runs matched specs, propagates their
  exit status; never blocks on a *missing* spec (warn + skip)
- C8: Flattened flake — every non-`nixpkgs` input is a `flake = false`
  source leaf; the cycle never enters the dependency graph

## §I Interfaces

- I.cli: `lefthook-bats-changed [--failures-only] <files...>` — main
  binary; selects matching specs, runs them, exit code is the bats run's
  status (exit 0 when no specs selected or no files given)
- I.companion: `find-bats-for-file.sh` — in-repo `.sh`→`.bats` path
  mapper, embedded into the main binary via `@FIND_BATS_FOR_FILE@`
  replacement (`writeText`); also runnable standalone (`bash
  find-bats-for-file.sh <path>`)
- I.nested: `lefthook-bats-failures-only` — built in-place from the
  `flake = false` `nix-lefthook-bats-failures-only-src` input and added
  to the main binary's `runtimeInputs`; invoked under `--failures-only`
- I.env: `LEFTHOOK_BATS_CHANGED_JOBS` (default `nproc`),
  `LEFTHOOK_BATS_CHANGED_TIMEOUT` (default 120, applied in lefthook.yml)
- I.remote: `lefthook-remote.yml` — consumers add as lefthook remote
  (pre-push `bats-changed` command on `*.{sh,bats}`)
- I.flake: `packages.${system}.default` — Nix pkg output
  (`lefthook-bats-changed`)
- I.devshell: `devShells.${system}.default` + `.#ci` — dev/CI shells,
  built inline from `flake = false` lint-hook source leaves
- I.ci: `.github/workflows/ci.yml` — linux + macos via
  `nix-lefthook-ci-action`; `update-pins.yml` refreshes `nixpkgs-lock`

## §V Invariants

- V1: `.bats` files under `tests/unit/` run directly when staged
- V2: A `.sh` file maps to its spec via `find-bats-for-file`: top-level
  `foo.sh` → `tests/unit/foo.bats`; nested `<dir>/foo.sh` →
  `tests/unit/<dir>/foo.bats`
- V3: Underscore→hyphen normalization: `my_tool.sh` matches
  `my-tool.bats`, falling back to `my_tool.bats` only when the hyphen
  form is absent
- V4: A `.sh` file with no matching spec warns on stderr and is skipped
  — never a hard failure (selection dispatcher, not a TDD gate)
- V5: No args, or no specs selected after mapping → exit 0
- V6: Non-existent staged paths are silently ignored
- V7: Non-`.sh`/non-`.bats` paths (e.g. `README.md`, `config.yml`) are
  silently skipped
- V8: Selected specs are de-duplicated (awk `!seen[$0]++`) before running
- V9: Parallelism = `LEFTHOOK_BATS_CHANGED_JOBS` else `nproc`; passed as
  `--jobs` to bats / the failures-only runner
- V10: `BATS_LIB_PATH` is unset before exec to avoid colon-joined
  collision with the wrapper's bats-with-libraries
- V11: `--failures-only` execs `lefthook-bats-failures-only`; otherwise
  execs `bats` directly
- V12: Exit status is that of the underlying bats/failures-only run —
  a failing spec fails the hook
- V13: `default` package embeds `find-bats-for-file.sh` via `writeText`
  and `@FIND_BATS_FOR_FILE@` replacement; `runtimeInputs` =
  `batsWithLibs` + `gawk` + `coreutils` + nested
  `lefthook-bats-failures-only`
- V14: `dev.sh` sets `BATS_LIB_PATH` and auto-installs lefthook when
  `.git/hooks/pre-commit` is missing; `ci` shell sets `BATS_LIB_PATH`
- V15: No credentials, secrets, tokens, API keys, or private paths in
  any tracked file
- V16: No hardcoded local filesystem paths (enforced by
  `nix-lefthook-git-no-local-paths` hook)
- V17: CI runs pre-commit + pre-push lint/test suite on linux + macos
- V18: All linters pass: shellcheck, shfmt, nixfmt, statix, deadnix,
  yamllint, typos, editorconfig-checker, bats-parse, bats-unit,
  nix-no-embedded-shell, trailing-whitespace, missing-final-newline,
  git-conflict-markers, git-no-local-paths, file-size-check,
  nix-flake-check
- V19: Flattened flake — only `nixpkgs-lock` (+ `nixpkgs` follows) are
  real flake inputs; every lint-hook companion and the failures-only
  runner come from `flake = false` `-src` leaves read via
  `${src}/<name>.sh`
- V20: `config/lefthook/file_size_limits.yml` raises the `nix` limit to
  10240 (flattened multi-input `flake.nix`) and `md` to 8192 (full SPEC.md)

## §T Tasks

| id | status | task | cites |
|----|--------|------|-------|
| T1 | x | core dispatcher: select `.bats` direct + `.sh`→spec, run, propagate exit | V1,V2,V4,V5,V12,I.cli |
| T2 | x | `find-bats-for-file.sh` companion: path map + underscore/hyphen normalization | V2,V3,I.companion |
| T3 | x | embed companion into binary via `@FIND_BATS_FOR_FILE@` `writeText` replace | V13,I.companion |
| T4 | x | non-existent / non-impl-non-spec paths ignored; de-dup selected specs | V6,V7,V8 |
| T5 | x | jobs from env else nproc; unset `BATS_LIB_PATH`; exec bats/failures-only | V9,V10,V11 |
| T6 | x | nested `lefthook-bats-failures-only` from `-src` leaf in runtimeInputs | V13,I.nested |
| T7 | x | Nix flake pkg (`writeShellApplication`) | C2,I.flake |
| T8 | x | flattened devShells: inline `mkShell` + lint-hook wrappers from `-src` leaves | C2,C8,V19,I.devshell |
| T9 | x | lefthook-remote.yml for consumers (pre-push) | I.remote |
| T10 | x | dev.sh — BATS_LIB_PATH + auto-install; ci shell BATS_LIB_PATH | V14 |
| T11 | x | unit tests: lefthook-bats-changed.bats (selection/skip/dedup) | V1-V8 |
| T12 | x | unit tests: find-bats-for-file.bats (mapping + normalization) | V2,V3 |
| T13 | x | unit tests: dev.bats (BATS_LIB_PATH + lefthook install) | V14 |
| T14 | x | GitHub Actions CI: linux + macos | V17,I.ci |
| T15 | x | linter suite via lefthook remotes | V18 |
| T16 | x | file_size_limits.yml: raise `nix` to 10240, `md` to 8192 | V20 |
| T17 | x | flatten flake: drop nix-dev-shell-agentic, all `flake = false` leaves | C8,V19 |
| T18 | x | opensource audit: no credentials/local-paths/private-refs | V15,V16,C5 |
