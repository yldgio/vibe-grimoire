# code-skills

> Reusable agentic skills, hooks, and policies for AI-augmented ("vibe") coding.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-3-blue)](#skills)

AI coding agents are only as good as their instructions. **code-skills** is a curated toolkit of structured prompt files — called _skills_ — that tell your agent exactly what to do, when to stop, and what tools are allowed.

Works with **GitHub Copilot CLI**, **OpenCode**, and **Claude Code**.

---

## Quick Start

Skills live in `skills/<name>/SKILL.md` (source) and are installed to `.agents/skills/<name>/SKILL.md` (runtime pickup).

**1. Clone this repo**
```bash
git clone https://github.com/yldgio/vibe-grimoire.git
```

**2. Install a skill into your project**
```bash
# From your project root
mkdir -p .agents/skills/setup-repo
cp path/to/code-skills/skills/setup-repo/SKILL.md .agents/skills/setup-repo/
```

**3. Invoke the skill** — tell your agent to "use the setup-repo skill" (Copilot CLI, OpenCode, or Claude Code all pick up `.agents/skills/` automatically).

> **Tip:** Use the [`setup-repo`](#setup-repo) skill itself to scaffold `.agents/skills/` in any new project.

---

## Skills

### `setup-repo`

Bootstrap or repair a project repository in one pass.

Covers: `git init`, `.gitignore`, `.gitattributes`, `AGENTS.md` (3–5 lines max), tool-constraint hooks, and skill installation.

**Scope guarantee:** Delivers a setup summary and returns control to you. It does not continue into implementation — even if it finds a design document or pending work in the repo.

```
skills/setup-repo/SKILL.md
skills/setup-repo/references/gitignore-patterns.md  # per-stack patterns
skills/setup-repo/evals/evals.json
```

---

### `tool-guard`

Enforce tool constraints across AI runtimes from a single policy file.

Define your preferred package manager, banned commands, and strictness level once in `hooks/tool-guard/policy.json`. The skill generates runtime-native enforcement for:

| Runtime | Output |
|---------|--------|
| GitHub Copilot CLI | `.github/hooks/tool-guard.json` + bash/PowerShell scripts |
| OpenCode | `.opencode/plugins/tool-guard/index.ts` |
| Claude Code | `.claude/hooks/pre-tool-guard.sh` + `.claude/settings.json` |

All scripts read `policy.json` at runtime — no hardcoded rules.

```
skills/tool-guard/SKILL.md
skills/tool-guard/references/copilot-cli.md
skills/tool-guard/references/opencode.md
skills/tool-guard/references/claude-code.md
```

---

### `pre-mortem`

Stress-test a plan before writing a single line of code.

Assumes the plan already failed, then interrogates every branch of the decision tree to surface why — and fix it before you start. Asks hard questions, recommends answers where it can, and outputs a `{project}-design.md`. Never applies changes directly.

```
skills/pre-mortem/SKILL.md
```

---

## Hooks

`hooks/tool-guard/policy.json` is the canonical tool policy for **this repo**. It demonstrates the tool-guard pattern:

- **Warns** on package-manager, task-runner, formatter, linter, and test-runner commands (this is a config-only repo — no install step needed)
- **Denies** destructive git operations (`reset --hard`, `checkout --`, `clean -fd`)

Runtime hook scripts in `.github/hooks/` (Copilot CLI) and `.claude/hooks/` (Claude Code) read this policy on every tool call.

---

## Sub-projects

| Project | Description |
|---------|-------------|
| [`opencode-browser/`](opencode-browser/) | Control a real Chromium browser (Chrome/Brave/Arc/Edge) from OpenCode using your existing profile |
| [`opencode-scheduler/`](opencode-scheduler/) | Run AI agents on a schedule — cron-style recurring tasks for OpenCode |

---

## Repo Structure

```
skills/           # Published skills — source of truth
├── setup-repo/
├── tool-guard/
└── plan-groom/

hooks/            # Canonical tool policies for this repo
.github/hooks/    # Copilot CLI runtime hook outputs
.opencode/        # OpenCode runtime hook outputs
.claude/          # Claude Code runtime hook outputs
.agents/skills/   # Runtime skill installs (local, gitignored)
```

---

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to add skills, report issues, and open pull requests.

## License

[MIT](LICENSE)
