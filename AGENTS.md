# AGENTS.md

## Project

A curated public collection of agentic skills, hooks, and agent configurations used
in daily vibe coding — shareable, reusable, cross-agent primitives.

## Stack & key paths

- **Content type**: Configuration files only (Markdown, YAML, JSON)
- **No build step** — this repo is pure configuration

```
skills/             # Published skills in skills/<skill-name>/SKILL.md
hooks/              # Canonical hook definitions and policy artifacts
agents/             # Custom agent definitions
```

## Commands

```bash
# No build or test commands — this is a configuration repo
git status                     # Check working tree
git log --oneline -20          # Review recent commits
```

## Conventions

- Every skill lives in its own folder: `skills/<skill-name>/SKILL.md`
- Every hook lives in its own folder: `hooks/<hook-name>/`, typically with `README.md` and any structured artifacts such as `policy.json`
- Every agent lives in its own folder: `agents/<agent-name>/<agent-name>.agent.md`
- Frontmatter (`name:`, `description:`) is required on every skill/agent file
- Keep descriptions under 300 chars — they appear in search results
- Filenames use `kebab-case`
- Local runtime/user skills belong in `.agents/skills/` in the target environment, not in this published collection
- Runtime-native hook outputs for target repos may live under `.github/hooks/` or `.opencode/plugins/`, but the published source of truth in this repo lives under `hooks/`

## Maintenance rules

- **Self-update**: whenever the repo structure, conventions, or folder layout change,
  update this file to reflect them. Keep AGENTS.md accurate and under 150 lines.
- **Documentation**: keep README.md (once created) and any docs/ files updated and
  in sync with the actual content of the repo. Never let documentation drift.
- **Git housework**: write clean, atomic commits. Use conventional commit format
  (feat / fix / docs / chore / refactor). Delete merged branches. Prefer rebase over
  merge when integrating changes into main. Keep the commit history readable.
- **Code hygiene**: before finishing any task, remove placeholder files, stale drafts,
  and any debug/test artifacts that were not meant to be committed.
