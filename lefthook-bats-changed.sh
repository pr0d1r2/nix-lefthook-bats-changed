# shellcheck shell=bash
# TDD pre-commit dispatcher: runs bats specs matching staged files.
#
# Selection rules:
#   - tests/unit/*.bats runs directly
#   - *.sh maps to tests/unit/<dir>/<stem>.bats
#   - Top-level .sh maps to tests/unit/<stem>.bats
#   - No matching spec: warn and skip
#
# NOTE: sourced by writeShellApplication — no shebang or set needed.

failures_only=0
if [ "${1:-}" = "--failures-only" ]; then
    failures_only=1
    shift
fi

if [ $# -eq 0 ]; then
    exit 0
fi

declare -a tests=()
declare -a missing=()

for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        tests/unit/*.bats)
            tests+=("$f")
            ;;
        *.sh)
            match=$(bash @FIND_BATS_FOR_FILE@ "$f")
            if [ -n "$match" ]; then
                tests+=("$match")
            else
                raw_stem="$(basename "$f")"
                raw_stem="${raw_stem%.sh}"
                norm_stem="${raw_stem//_/-}"
                dir="$(dirname "$f")"
                if [ "$dir" = "." ]; then
                    missing+=("$f -> tests/unit/${norm_stem}.bats")
                else
                    missing+=("$f -> tests/unit/${dir}/${norm_stem}.bats")
                fi
            fi
            ;;
    esac
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo "bats-changed: WARN: no spec found for staged file(s) — skipped:" >&2
    printf '  %s\n' "${missing[@]}" >&2
fi

if [ "${#tests[@]}" -eq 0 ]; then
    exit 0
fi

mapfile -t tests < <(printf '%s\n' "${tests[@]}" | awk '!seen[$0]++')

echo "bats-changed: running ${#tests[@]} spec(s) for staged changes"
if [ "$failures_only" -eq 1 ]; then
    exec lefthook-bats-failures-only --jobs "$(nproc)" "${tests[@]}"
else
    exec bats --jobs "$(nproc)" "${tests[@]}"
fi
