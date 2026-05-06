# AGENTS.md
Project: Curated collection of reusable agentic skills, hooks, and agent configs for vibe coding.
Stack: Markdown, YAML, JSON — configuration only, no build step.
Key paths: `skills/` published skills · `hooks/` canonical policies · `.github/hooks/` + `.opencode/plugins/` runtime outputs · `.agents/skills/` local runtime skills · `kaizen/` continuous-improvement notes (auto-written by the kaizen skill on every correction)

## Memory

If `memento-memento_context_assemble` is available, call it at the start of each session with `project="vibe-grimoire"` to load persisted context. Use the memento tools to log non-obvious decisions and patterns discovered during the session — not facts already documented here. Skip entirely if the tool is not present.

## Kaizen Learnings

<!-- Populated automatically by the kaizen skill. One line per entry. -->
- **2026-03-30** [git push without -u does not set upstream tracking](kaizen/20260330-git-push-no-upstream.md) — always use `git push -u origin <branch>` or follow up with `git branch --set-upstream-to`
- **2026-05-06** [keep skill descriptions under 900 characters](kaizen/20260506-skill-desc-limit.md) — frontmatter descriptions are registry metadata; keep them concise and within the repo limit

