# shellcheck shell=bash
# Maps a .sh file path to its matching .bats test path.
# Usage: bash find-bats-for-file.sh <file-path>
# Prints the .bats path to stdout if found, or nothing if not.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

f="$1"

raw_stem="$(basename "$f")"
raw_stem="${raw_stem%.sh}"
norm_stem="${raw_stem//_/-}"
dir="$(dirname "$f")"

if [ "$dir" = "." ]; then
    candidate="tests/unit/${norm_stem}.bats"
    alt="tests/unit/${raw_stem}.bats"
else
    candidate="tests/unit/${dir}/${norm_stem}.bats"
    alt="tests/unit/${dir}/${raw_stem}.bats"
fi

if [ -f "$candidate" ]; then
    echo "$candidate"
elif [ "$raw_stem" != "$norm_stem" ] && [ -f "$alt" ]; then
    echo "$alt"
fi
