---
name: setup-repo
description: >-
  Bootstrap a new project/repository from scratch with all the essentials: AGENTS.md,
  git init, .gitignore, .gitattributes, and relevant Copilot skills. USE THIS SKILL
  when the user wants to set up a new repo, initialize a project folder, bootstrap a
  working directory, scaffold a project from scratch, or do a fresh project setup —
  even if they don't say "setup-repo". Triggers on: "set up my repo", "bootstrap this
  project", "init a new project", "prepare this folder", "set up git with my
  preferences", "scaffold a project", "create project structure", "initialize my
  workspace".
---

# Setup Repo

This skill bootstraps a new project folder with the user's preferences. It interviews the user, inspects the folder, then sets up git infrastructure, AGENTS.md, and installs relevant Copilot skills in one go.

## Step 1: Interview the user

Use `ask_user` to collect these three things before touching any files:

1. **Project goal** — one sentence: what is this project for?
2. **Tech stack** — languages, frameworks, runtimes (e.g., "Python, FastAPI, Postgres" or "TypeScript, React, Vite")
3. **Skills** — any specific Copilot skills they want added by name (optional; you'll suggest more in Step 7)

If files already exist in the folder (source files, config files), scan them first and pre-fill or suggest answers to reduce friction.

If the user skips the interview, infer everything from the folder contents and proceed with sensible defaults. Note what was inferred in your summary.

## Step 2: Scan the current folder

Inspect the working directory before generating any files:

- Detect source files by extension (`.py`, `.ts`, `.js`, `.go`, `.cs`, `.java`, `.rs`, `.rb`, etc.)
- Detect config files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `*.csproj`, `Dockerfile`, `.github/`, etc.)
- Note any existing documentation (README.md, docs/)

This scan informs the gitignore, gitattributes, and skills selection. Don't guess the stack — use what you actually find.

## Step 3: Initialize git

```bash
git init
```

If `.git` already exists, skip this and note it in the final summary.

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

Add linguist-vendored overrides for generated files if present (e.g., `dist/** linguist-vendored`). Add `merge=ours` for lock files if the stack uses them (e.g., `package-lock.json merge=ours`).

## Step 6: Create AGENTS.md

Create `AGENTS.md` at the project root. It must stay **under 150 lines** — keep it focused and scannable.

Structure it as:
1. **Project** — one-line description (from the interview)
2. **Stack & key paths** — languages, frameworks, main directories
3. **Commands** — build, test, lint (leave as `# TODO` if not yet known)
4. **Conventions** — any coding rules visible from the repo (or leave minimal if brand new)
5. **Maintenance rules** — the four rules below are **mandatory** and must appear in every generated AGENTS.md

### Mandatory maintenance rules block

Include this section verbatim (tailor wording slightly to the project if needed, but preserve all four rules):

```markdown
## Maintenance rules

- **Self-update**: whenever the repo structure, stack, or conventions change, update this file to
  reflect them. Keep AGENTS.md accurate and under 150 lines at all times.
- **Documentation**: keep README.md and all files under docs/ updated and in sync with code
  changes. Never let documentation drift from the implementation.
- **Git housework**: write clean, atomic commits. Use conventional commit format
  (feat / fix / docs / chore / refactor / test). Delete merged branches. Prefer rebase over
  merge when integrating feature branches into main. Keep the commit history readable.
- **Code hygiene**: before finishing any task, remove dead code, unused imports, commented-out
  blocks, and debug artifacts.
```

Do not exceed 150 lines. If you are approaching the limit, cut prose, not the maintenance rules.

## Step 7: Install relevant Copilot skills

Based on the stack and the user's stated preferences, find and add relevant skills as agentic skill files in the project.

### Automatic skill mapping

| Stack / tool                          | Skills to add                                        |
|---------------------------------------|------------------------------------------------------|
| Docker / containers                   | `docker`                                             |
| GitHub Actions / CI                   | `github-actions`, `github-actions-templates`         |
| .NET / C# / ASP.NET                   | `dotnet`                                             |
| Kubernetes / k8s                      | `k8s-manifest-generator`, `k8s-security-policies`    |
| Any GitHub-hosted project             | `gh-cli`, `conventional-commit`, `git-advanced-workflows` |
| Any project (always consider)         | `conventional-commit`                                |

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

## Step 8: Summarize

After all steps, give the user a concise checklist:

```
✅ git init (or ⏭ already initialized)
✅ .gitignore created (Python + secrets)
✅ .gitattributes created
✅ AGENTS.md created (87 lines)
✅ Skills added to .agents/skills/: conventional-commit, docker, gh-cli
```

If anything couldn't be completed (e.g., a requested skill wasn't found), note it clearly and suggest alternatives.
