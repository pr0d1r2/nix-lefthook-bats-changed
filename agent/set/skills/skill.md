# Skill meta

The `agent/set/skills/` tree holds this project's behavioral rules, one concept per file. It is structured, not flat: a top-level `<topic>.md` captures the core rule for a topic, and `<topic>/<aspect>.md` captures a specific facet of it (e.g. `sh.md` + `sh/modularity.md`, `lefthook.md` + `lefthook/{nix,sh}.md`).

Every file here is chain-loaded into every session via `agent/set.md` (which the project `CLAUDE.md` @-imports). When you need to check whether a topic has a rule, prefer listing or grepping this tree over guessing.

When adding a new skill:

- Put a single-topic rule at `agent/set/skills/<topic>.md`.
- Put a narrower facet of an existing topic at `agent/set/skills/<topic>/<aspect>.md`.
- Add the new file as an `@./set/skills/...` import line in `agent/set.md` so it chain-loads.

When a skill file is added or changed, apply its rules to the entire repo immediately. Scan all existing files for violations. Fix each violation in a separate commit.
