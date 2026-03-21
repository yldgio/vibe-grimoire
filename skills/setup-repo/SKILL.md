---
name: setup-repo
description: >-
  Bootstrap a new project/repository from scratch with all the essentials: AGENTS.md,
  git init, .gitignore, .gitattributes, and relevant agentic skills. USE THIS SKILL
  when the user wants to set up a new repo, initialize a project folder, bootstrap a
  working directory, scaffold a project from scratch, or do a fresh project setup —
  even if they don't say "setup-repo". Triggers on: "set up my repo", "bootstrap this
  project", "init a new project", "prepare this folder", "set up git with my
  preferences", "scaffold a project", "create project structure", "initialize my
  workspace".
---

# Setup Repo

This skill bootstraps a new project folder with the user's preferences. It interviews the user, inspects the folder, then sets up git infrastructure, a minimal AGENTS.md, hook-based tool constraints, and relevant agentic skills in one go.

## Step 1: Interview the user

ask the user to collect these core things before touching any files:

1. **Project goal** — one sentence: what is this project for?
2. **Tech stack** — languages, frameworks, runtimes (e.g., "Python, FastAPI, Postgres" or "TypeScript, React, Vite")
3. **Skills** — any specific agentic skills they want added by name (optional; you'll suggest more in Step 8)

When the project has tool-driven workflow constraints, also collect:

4. **Runtime targets** — which runtimes should get generated enforcement hooks (`GitHub Copilot CLI`, `OpenCode`)
5. **Tool constraints** — package manager, task runner/scripts, formatter, linter, test runner, and extra banned commands
6. **Strictness** — whether each category is hard-blocked or warning-only

If files already exist in the folder (source files, config files), scan them first and pre-fill or suggest answers to reduce friction.

If the user skips the interview, infer everything from the folder contents and proceed with sensible defaults. Note what was inferred in your summary.

## Step 2: Explore the current folder

use a subagent to explore and inspect the working directory before generating any files:

- Detect source files by extension 
- Detect config files
- Note any existing documentation

This scan informs the gitignore, gitattributes, and skills selection. Don't guess the stack — use what you actually find.

## Step 3: Initialize git

If `.git` already exists, skip this and note it in the final summary.
```bash
git init .
```


## Step 4: Create .gitignore

Generate a `.gitignore` tailored to the detected/declared stack. Structure it with labeled sections:

**Always include:**
- OS artifacts: `.DS_Store`, `Thumbs.db`, `desktop.ini`
- Editor artifacts: `.vscode/`, `.idea/`, `*.swp`, `*.swo`, `*.orig`
- Secrets: `.env`, `.env.local`, `.env.*.local`, `*.pem`, `*.key`, `*.p12`

**Stack-specific examples** (use whichever apply):
- Python: `__pycache__/`, `*.pyc`, `*.pyo`, `.venv/`, `dist/`, `*.egg-info/`, `.pytest_cache/`, `.mypy_cache/`
- Node/TS: `node_modules/`, `dist/`, `build/`, `.next/`, `.nuxt/`, `*.tsbuildinfo`
- Go: `/bin/`, `*.test`, `coverage.out`
- .NET: `bin/`, `obj/`, `*.user`, `*.suo`, `.vs/`
- Rust: `/target/`
- Java/Gradle/Maven: `build/`, `.gradle/`, `target/`, `*.class`, `*.jar`
- General: `coverage/`, `.coverage`, `*.log`, `tmp/`, `*.tmp`

If multiple stacks are present, combine sections with clear `# --- Section Name ---` comments.

## Step 5: Create .gitattributes

Generate a `.gitattributes` that handles cross-platform consistency and binary files:

```gitattributes
# Auto-detect text files and normalize line endings to LF
* text=auto eol=lf

# Explicitly declare text files
*.md text
*.json text
*.yaml text
*.yml text
*.toml text
*.sh text eol=lf

# Binary files — do not diff or merge
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.svg binary
*.woff binary
*.woff2 binary
*.ttf binary
*.eot binary
*.zip binary
*.tar.gz binary
*.pdf binary
```

Add linguist-vendored overrides for generated files if present (e.g., `dist/** linguist-vendored`).

## Step 6: Create AGENTS.md

Create `AGENTS.md` at the target project root. It must stay **between 3 and 5 lines** total.

Treat it as a tiny orientation card, not a policy file:

- Include the project in one line
- Include stack only when the project is genuinely multi-stack
- Include key paths only for large projects
- Do **not** put maintenance rules, tool policies, or hook instructions in `AGENTS.md`

Default template:

```markdown
# AGENTS.md
Project: <one-line purpose>
Stack: <only if multi-stack>
Key paths: <only if large project>
```

If the project is simple and single-stack, 3 lines is fine. Never exceed 5 lines.
This rule is for generated target repos, not for the published skill-collection repo that may document broader conventions.

## Step 7: Capture tool constraints and generate hooks

If the project has explicit tool preferences or restrictions, move that policy out of `AGENTS.md` and into hooks.

### Constraints to capture

- Package manager
- Task runner / scripts
- Formatter
- Linter
- Test runner
- Extra banned commands

For each category, collect:

- Preferred tool/command
- Disallowed alternatives
- Whether the category is hard-blocked or warning-only

### Hook generation flow

1. Ask which runtimes to generate for (`GitHub Copilot CLI`, `OpenCode`)
2. Ask for confirmation before generating runtime files
3. Create canonical hook artifacts in `hooks/tool-guard/`
4. Use the `tool-guard` skill to generate runtime-native enforcement files when it is available

Canonical artifacts must include:

- `hooks/tool-guard/README.md`
- `hooks/tool-guard/policy.json`

Runtime-native outputs must be generated per selected runtime:

- **GitHub Copilot CLI** → `.github/hooks/*.json` with `preToolUse` enforcement
- **OpenCode** → `.opencode/plugins/` hook plugin plus any required `opencode.json` wiring

Keep all operational tool policy in hooks, not in `AGENTS.md`.

If `tool-guard` is not available, still create the canonical `hooks/tool-guard/` artifacts and clearly report that runtime-native hook generation was skipped.

## Step 8: Install relevant agentic skills

Based on the stack, the user's stated preferences, and whether hook-based policy is needed, find and add relevant skills as agentic skill files in the project.

### Automatic skill mapping

| Stack / tool                          | Skills to add                                        |
|---------------------------------------|------------------------------------------------------|
| Docker / containers                   | `docker`                                             |
| GitHub Actions / CI                   | `github-actions`, `github-actions-templates`         |
| .NET / C# / ASP.NET                   | `dotnet`                                             |
| Kubernetes / k8s                      | `k8s-manifest-generator`, `k8s-security-policies`    |
| Any GitHub-hosted project             | `gh-cli`, `conventional-commit`, `git-advanced-workflows` |
| Any project (always consider)         | `conventional-commit`                                |
| Explicit tool constraints / runtime hooks | `tool-guard`                                      |

### How to add skills

Skills MUST always be installed to `.agents/skills/` in the project root — this is the
cross-agent standard location picked up by both Copilot CLI and opencode.

1. Use `awesome-copilot-search_instructions` with stack-relevant keywords to find matching skills.
2. Use `awesome-copilot-load_instruction` to read each skill's content.
3. Create the directory `.agents/skills/<skill-name>/` inside the project root.
4. Write the skill content as `.agents/skills/<skill-name>/SKILL.md`.

**Never** install project skills to `.github/extensions/`, `skills/`, or any other path.
`.agents/skills/` is the only correct location for cross-agent compatibility.

Also add any skills the user explicitly requested by name in the interview (Step 1).

Tell the user which skills were added and why (one line each).

## Step 9: Summarize

After all steps, give the user a concise checklist:

```
✅ git init (or ⏭ already initialized)
✅ .gitignore created (Python + secrets)
✅ .gitattributes created
✅ AGENTS.md created (3–5 lines)
✅ Tool constraints captured in hooks/tool-guard/
✅ Runtime hooks generated for: GitHub Copilot CLI, OpenCode
✅ Skills added to .agents/skills/: conventional-commit, docker, gh-cli
```

If anything couldn't be completed (e.g., a requested skill wasn't found), note it clearly and suggest alternatives.
