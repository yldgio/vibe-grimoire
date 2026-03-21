# AGENTS.md

## Project

A curated public collection of agentic skills, hooks, and agent configurations used
in daily vibe coding — shareable, reusable, cross-agent primitives.

## Stack & key paths

- **Content type**: Configuration files only (Markdown, YAML, JSON)
- **No build step** — this repo is pure configuration

```
skills/             # Published skills in skills/<skill-name>/SKILL.md
.github/agents/     # Repo-local custom agent definitions
.agents/skills/     # Local runtime/user skills for this environment
```

## Commands

```bash
# No build or test commands — this is a configuration repo
git status                     # Check working tree
git log --oneline -20          # Review recent commits
```

## Conventions

- Every published skill lives in its own folder: `skills/<skill-name>/SKILL.md`
- Repo-local runtime/user skills live under `.agents/skills/<skill-name>/SKILL.md` and stay separate from published `skills/`
- Current custom agents in this repo live under `.github/agents/<agent-name>.agent.md`
- If canonical hooks are added to this collection, store them in `hooks/<hook-name>/`, typically with `README.md` and any structured artifacts such as `policy.json`
- Frontmatter (`name:`, `description:`) is required on every published skill/agent file
- Keep descriptions under 300 chars — they appear in search results
- Filenames use `kebab-case`
- Runtime-native hook outputs for target repos may live under `.github/hooks/` or `.opencode/plugins/`; keep them separate from any canonical `hooks/` content when hooks are added here

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
