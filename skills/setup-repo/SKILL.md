---
name: setup-repo
description: >-
  Set up or repair a project repository: bootstrap a new repo or update an
  existing initialized project with AGENTS.md, .gitignore, .gitattributes,
  hooks, and relevant skills. Use whenever the user wants to set up, refresh,
  normalize, or fix repo scaffolding.
---

# Setup Repo

This skill sets up or repairs a repository. The same rules apply whether the project is new or already initialized — inspect first, then apply each step.

## Scope

This skill delivers repo scaffolding only: git initialization, `.gitignore`, `.gitattributes`, `AGENTS.md`, hooks, and skill installation. The summary in Step 9 is the final deliverable. Once it is delivered, this skill's work is complete — what happens next is the user's decision.

## Step 1: Interview the user

Collect before touching any files:

1. **Project goal** — one sentence: what is this project for?
2. **Tech stack** — languages, frameworks, runtimes
3. **Skills** — any specific agentic skills to add (optional)

If the project has tool constraints, also collect:

4. **Runtime targets** — which runtimes need enforcement hooks (`GitHub Copilot CLI`, `OpenCode`)
5. **Tool constraints** — package manager, task runner, formatter, linter, test runner, banned commands
6. **Strictness** — hard-block or warning-only per category

If files already exist, scan them first and pre-fill answers to reduce friction. If the user skips the interview, infer everything from folder contents and note what was inferred in the summary.

## Step 2: Explore the folder

Inspect the working directory before generating any files:

- Whether `.git` exists
- Source and config files (detect the stack)
- Which setup surfaces already exist: `.gitignore`, `.gitattributes`, `AGENTS.md`, `hooks/`, `.github/hooks/`, `.opencode/plugins/`, `.agents/skills/`

Don't guess the stack — use what you actually find.

## Step 3: Initialize git

If `.git` already exists, skip and note it in the summary.

```bash
git init .
```

## Step 4: Create or update .gitignore

Read `references/gitignore-patterns.md` for comprehensive per-stack patterns.

Generate a `.gitignore` tailored to the detected stack, or merge missing patterns into an existing one. Always include the **Universal** section; add only the stack-specific sections that apply. Prefer additive edits; preserve existing custom patterns and comments.

## Step 5: Create or update .gitattributes

Generate or update `.gitattributes` for cross-platform line-ending consistency and binary file handling:

```gitattributes
* text=auto eol=lf
*.md text
*.json text
*.yaml text
*.yml text
*.toml text
*.sh text eol=lf
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.svg binary
*.woff binary
*.woff2 binary
*.ttf binary
*.zip binary
*.tar.gz binary
*.pdf binary
```

Add `dist/** linguist-vendored` if generated output directories are present.

## Step 6: Create or update AGENTS.md

**AGENTS.md must always be exactly 3–5 lines. No exceptions — new project or existing.**

It is a tiny orientation card, nothing more. Do not put maintenance rules, tool policies, conventions, or commands in it.

```markdown
# AGENTS.md
Project: <one-line purpose>
Stack: <only if genuinely multi-stack>
Key paths: <only if large multi-directory project>
```

If the file does not exist, create it. If it exists and is longer than 5 lines, rewrite it to fit the template above — extract the essentials and discard the rest. Tool policy belongs in `hooks/`, not here.

## Step 7: Capture tool constraints and generate hooks

If the project has tool preferences or restrictions, store them in `hooks/tool-guard/` — not in `AGENTS.md`.

Create:
- `hooks/tool-guard/README.md` — human summary of the policy
- `hooks/tool-guard/policy.json` — structured policy (runtimes, categories with preferred/blocked/mode, extra banned commands)

Then generate runtime-native enforcement:
- **GitHub Copilot CLI** → `.github/hooks/tool-guard.json` + scripts under `.github/hooks/scripts/`
- **OpenCode** → `.opencode/plugins/tool-guard/index.ts` + any `opencode.json` wiring

Use the `tool-guard` skill when available. If existing hook files are present, update or extend them rather than duplicating. Ask before replacing enforcement logic the project already relies on.

## Step 8: Install relevant skills

Install skills to `.agents/skills/<skill-name>/SKILL.md` — this is the only correct location.

| Stack / trigger | Skills to add |
|---|---|
| Docker | `docker` |
| GitHub Actions / CI | `github-actions`, `github-actions-templates` |
| .NET / C# | `dotnet` |
| Kubernetes | `k8s-manifest-generator`, `k8s-security-policies` |
| Any GitHub project | `gh-cli`, `conventional-commit`, `git-advanced-workflows` |
| Tool constraints / hooks | `tool-guard` |

1. Search with `awesome-copilot-search_instructions`
2. Load with `awesome-copilot-load_instruction`
3. Write to `.agents/skills/<skill-name>/SKILL.md`

If a skill is already installed and current, leave it. Refresh only if stale or explicitly requested.

## Step 9: Summarize

```
✅ git init  (or ⏭ already initialized)
✅ .gitignore  created / updated / unchanged
✅ .gitattributes  created / updated / unchanged
✅ AGENTS.md  created / rewritten to 3–5 lines
✅ hooks/tool-guard/  created / updated
✅ Runtime hooks for: GitHub Copilot CLI, OpenCode
✅ Skills added/refreshed: conventional-commit, gh-cli
```

Note anything that could not be completed and what action the user may want to take next.

**Your work is complete.** Deliver this summary and return control to the user. The next step is theirs to decide.