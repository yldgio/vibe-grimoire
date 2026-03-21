---
name: setup-repo
description: >-
  Set up or repair a project repository: bootstrap a new repo or update an
  existing initialized project with AGENTS.md, .gitignore, .gitattributes,
  hooks, and relevant skills. Use whenever the user wants to set up, refresh,
  normalize, or fix repo scaffolding.
---

# Setup Repo

This skill bootstraps a new project folder or repairs an existing one. Start by inspecting what is already present, then choose between bootstrap mode and update/repair mode. In existing repos, prefer safe additive changes and ask before rewriting conflicting customized setup files.

## Step 1: Interview the user

Ask the user to collect these core things before touching files:

1. **Project goal** — one sentence: what is this project for?
2. **Tech stack** — languages, frameworks, runtimes (e.g., "Python, FastAPI, Postgres" or "TypeScript, React, Vite")
3. **Skills** — any specific agentic skills they want added by name (optional; you'll suggest more in Step 8)
4. **Setup scope** — for an existing project, should you audit only, add missing setup, or refresh/normalize repo setup?

When the project has tool-driven workflow constraints, also collect:

5. **Runtime targets** — which runtimes should get generated enforcement hooks (`GitHub Copilot CLI`, `OpenCode`)
6. **Tool constraints** — package manager, task runner/scripts, formatter, linter, test runner, and extra banned commands
7. **Strictness** — whether each category is hard-blocked or warning-only

If files already exist in the folder (source files, config files), scan them first and pre-fill or suggest answers to reduce friction.

If the user skips the interview, infer everything from the folder contents and proceed with sensible defaults. For existing repos, default to audit-first behavior and ask before rewriting conflicting setup files. Note what was inferred in your summary.

## Step 2: Explore the current folder and classify repo state

Use a subagent when available; otherwise inspect the working directory inline before generating files. Determine:

- Whether `.git` already exists
- Whether project files exist without `.git`
- Source files by extension
- Config files
- Existing documentation
- Existing setup surfaces:
  - `.gitignore`
  - `.gitattributes`
  - `AGENTS.md`
  - `hooks/`
  - `.github/hooks/`
  - `.opencode/plugins/`
  - `.agents/skills/`

Classify each setup surface as:

- missing
- present and good
- present but partial/outdated
- present and user-customized/conflicting

This scan informs the gitignore, gitattributes, hooks, AGENTS.md, and skills selection. Don't guess the stack — use what you actually find.

## Step 3: Choose the operating mode

### Mode A: New / bootstrap

Use this when the folder is empty or the user clearly wants a brand-new repo.

- Create missing repo scaffolding from scratch.
- Use the declared or detected stack to generate sensible defaults.

### Mode B: Initialize an existing non-git folder

Use this when project files exist but `.git` does not.

- Treat the existing source/config files as authoritative for stack detection.
- Add repo scaffolding around the project without disturbing application files.

### Mode C: Update / repair an existing repo

Use this when `.git` already exists or the user explicitly wants to fix repo setup.

- Audit first.
- Create missing setup artifacts directly when low-risk.
- Apply targeted, merge-safe updates to partial/outdated setup.
- Ask before rewriting customized or conflicting setup files.
- Preserve unrelated project files and repo-specific conventions unless the user asks to normalize them.

## Step 4: Initialize git only when needed

If `.git` already exists, skip this and note it in the final summary.

If project files exist but `.git` does not, initialize git only after confirming the current folder is the intended project root.

```bash
git init .
```


## Step 5: Create or update .gitignore

When `.gitignore` is missing, generate one tailored to the detected/declared stack.

When `.gitignore` already exists:

- preserve existing custom patterns and comments
- merge in missing high-value ignores for the detected stack
- deduplicate obvious duplicates
- prefer additive edits over full replacement
- ask before replacing a clearly customized file wholesale

Structure generated content with labeled sections:

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

If the existing file already covers the detected stack well, leave it unchanged and report that no update was needed.

## Step 6: Create or update .gitattributes

When `.gitattributes` is missing, generate a file that handles cross-platform consistency and binary files.

When `.gitattributes` already exists:

- preserve project-specific text/binary rules
- add missing normalization rules only where safe
- add vendored/generated overrides when clearly applicable
- ask before broad rewrites if the file already encodes non-trivial merge or linguist behavior

Baseline content:

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

## Step 7: Create or update AGENTS.md

Create `AGENTS.md` at the target project root when it is missing. It must stay **between 3 and 5 lines** total.

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

When `AGENTS.md` already exists:

- if it is already a small orientation card, refresh it only if it is obviously stale
- if it contains substantial project-specific guidance, do not blindly replace it
- prefer targeted edits or ask the user before shrinking/reformatting a customized file

This rule is for generated target repos, not for the published skill-collection repo that may document broader conventions.

## Step 8: Capture tool constraints and generate hooks

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
3. Create or update canonical hook artifacts in `hooks/tool-guard/`
4. Use the `tool-guard` skill to generate or refresh runtime-native enforcement files when it is available

In update/repair mode:

- inspect existing `hooks/tool-guard/`, `.github/hooks/`, `.opencode/plugins/`, and related runtime wiring before generating new files
- if compatible artifacts already exist, update or extend them rather than duplicating them
- ask before replacing conflicting enforcement logic the project already relies on

Canonical artifacts must include:

- `hooks/tool-guard/README.md`
- `hooks/tool-guard/policy.json`

Runtime-native outputs must be generated per selected runtime:

- **GitHub Copilot CLI** → `.github/hooks/*.json` with `preToolUse` enforcement
- **OpenCode** → `.opencode/plugins/` hook plugin plus any required `opencode.json` wiring

Keep all operational tool policy in hooks, not in `AGENTS.md`.

If `tool-guard` is not available, still create or update the canonical `hooks/tool-guard/` artifacts and clearly report that runtime-native hook generation was skipped.

## Step 9: Install or refresh relevant agentic skills

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

If a skill is already installed:

- leave it in place if it still matches the user's intent
- refresh it when it is obviously stale or the user asked for an update
- avoid duplicate directories or duplicate installs

**Never** install project skills to `.github/extensions/`, `skills/`, or any other path.
`.agents/skills/` is the only correct location for cross-agent compatibility.

Also add any skills the user explicitly requested by name in the interview (Step 1).

Tell the user which skills were added, refreshed, or left unchanged, and why (one line each).

## Step 10: Summarize

After all steps, give the user a concise checklist that distinguishes between created, updated, skipped, and unchanged items:

```
✅ git init (or ⏭ already initialized)
✅ .gitignore created or updated (Python + secrets)
✅ .gitattributes created or updated
✅ AGENTS.md created or refreshed
✅ Tool constraints captured in hooks/tool-guard/
✅ Runtime hooks generated or reviewed for: GitHub Copilot CLI, OpenCode
✅ Skills added or refreshed in .agents/skills/: conventional-commit, docker, gh-cli
⏭ Existing custom hooks left unchanged pending confirmation
```

If anything couldn't be completed (e.g., a requested skill wasn't found, or an existing customized file was left untouched pending approval), note it clearly and suggest alternatives or the next confirmation needed.
