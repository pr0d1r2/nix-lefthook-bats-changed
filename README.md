# nix-lefthook-bats-changed

[![CI](https://github.com/pr0d1r2/nix-lefthook-bats-changed/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-bats-changed/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [Bats](https://github.com/bats-core/bats-core) changed-files runner, packaged as a Nix flake.

TDD pre-commit dispatcher that runs only bats specs matching staged files. Maps `.sh` files to their corresponding `tests/unit/` specs and runs `.bats` files directly. Depends on [nix-lefthook-bats-failures-only](https://github.com/pr0d1r2/nix-lefthook-bats-failures-only) for `--failures-only` mode.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-bats-changed
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-bats-changed = {
  url = "github:pr0d1r2/nix-lefthook-bats-changed";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-bats-changed.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-push:
  commands:
    bats-changed:
      glob: "*.{sh,bats}"
      run: timeout ${LEFTHOOK_BATS_CHANGED_TIMEOUT:-120} lefthook-bats-changed {push_files}
```

### Configuring timeout

The default timeout is 120 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_BATS_CHANGED_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-bats-changed  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
