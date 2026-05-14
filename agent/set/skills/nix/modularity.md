# Nix modularity

Do not store embedded shell in nix files but rather extract them to shell scripts and parametrize their input.
For every file extracted this way add watch_file entry to .envrc file.
Do not store embedded XML in nix files but rather extract them to separate files.
Nix modules should not be dependent on other nix modules. If something like this happen modularize further to extract common part.
