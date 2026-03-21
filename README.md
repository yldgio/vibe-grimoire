# code-skills

Curated collection of reusable agentic skills, hooks, and agent configs for vibe coding.

## Skills

### `setup-repo`
**Path:** `skills/setup-repo/SKILL.md`

Sets up or repairs a project repository. Bootstraps a new repo or updates an existing one with `AGENTS.md`, `.gitignore`, `.gitattributes`, hooks, and relevant skills.

**Scope:** Repo scaffolding only — git init through skill installation. Delivers a summary and hands control back to the user. What happens next is always the user's decision.

**Use when:** setting up, refreshing, normalizing, or repairing repo scaffolding.

---

### `tool-guard`
**Path:** `skills/tool-guard/SKILL.md`

Creates runtime-aware hook enforcement for tool constraints (package managers, task runners, formatters, linters). Generates policies for GitHub Copilot CLI and OpenCode.

**Use when:** enforcing tool policy, blocking banned commands, or generating Copilot/OpenCode hooks.

---

### `plan-groom`
**Path:** `skills/plan-groom/SKILL.md`

Relentlessly interrogates a user's plan or design to reach shared understanding, walking every branch of the decision tree.

**Use when:** stress-testing a plan, doing rigorous design discovery before implementation.

---

## Structure

```
skills/          # Published skills (source of truth)
hooks/           # Canonical tool policies
.github/hooks/   # GitHub Copilot CLI runtime outputs
.opencode/       # OpenCode runtime outputs
.agents/skills/  # Local runtime skill installs
```
