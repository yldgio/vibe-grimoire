# code-skills

> Reusable agentic skills, hooks, and policies for AI-augmented ("vibe") coding.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-15-blue)](#skills)

AI coding agents are only as good as their instructions. **code-skills** is a curated toolkit of structured prompt files — called _skills_ — that tell your agent exactly what to do, when to stop, and what tools are allowed.

Works with **GitHub Copilot CLI**, **OpenCode**, and **Claude Code**.

---

## Quick Start

Skills live in `skills/<name>/SKILL.md` (source) and are installed to `.agents/skills/<name>/SKILL.md` (runtime pickup).

### Option A — one-liner with npx (recommended)

```bash
npx skills install https://github.com/yldgio/vibe-grimoire --skill setup-repo
```

Install multiple skills at once:

```bash
npx skills install https://github.com/yldgio/vibe-grimoire \
  --skill setup-repo \
  --skill create-prd \
  --skill prd-slice
```

### Option B — manual copy

```bash
# From your project root
git clone https://github.com/yldgio/vibe-grimoire.git /tmp/vibe-grimoire
mkdir -p .agents/skills/setup-repo
cp /tmp/vibe-grimoire/skills/setup-repo/SKILL.md .agents/skills/setup-repo/
```

### Invoke the skill

Tell your agent: *"use the setup-repo skill"* — GitHub Copilot CLI, OpenCode, and Claude Code all pick up `.agents/skills/` automatically.

> **Tip:** Use the [`setup-repo`](#setup-repo) skill itself to scaffold `.agents/skills/` in any new project.

---

## Skills

### PRD Workflow

Several skills chain together to take a feature idea all the way to tracked work items:

```
create-prd ──► pre-mortem (optional) ──► plan-from-prd ──► prd-slice
   │                  │                        │                │
Write the PRD   Stress-test         Local phased plan    Tracker issues
               before coding       (./plans/*.md)     (AzDO / GH / Jira)
```

Each skill is independently useful — use any one in isolation or chain them in sequence.

---

### Bug Workflow

Two skills cover the full bug lifecycle — from raw symptom to tracked, actionable issue:

```
triage-bug ──────────────────────────────────────────► report-issue
     │                                                       │
 Investigate codebase,                             File structured issue
 find root cause,                                  in GitHub / AzDO / Jira
 design TDD fix plan                               (also usable standalone)
```

`triage-bug` calls `report-issue` automatically at the end. Use `report-issue` directly when you already know the problem and just need to log it.

---

### `adr`

Capture significant architectural choices as durable, human-readable records that explain *why* the codebase is shaped the way it is.

- **Decision-first workflow** — extracts context, problem, and trade-offs from conversation; confirms draft before saving
- **Existing ADR awareness** — checks the `docs/adr/` directory to determine the next sequential number and identify related or superseded decisions
- **Honest trade-offs** — template enforces both positive *and* negative consequences; an ADR with only upsides is flagged as incomplete
- **Rejection rationale for alternatives** — explains why each alternative was not chosen, which is the most valuable part for future readers
- **Optional sections** — `Alternatives Considered`, `Implementation Notes`, and `References` are included only when they add value
- **Status lifecycle** — guides Proposed → Accepted → Superseded transitions with clear semantics

```
skills/adr/SKILL.md
```

---

### `create-prd`

Capture a feature from scratch: interview the user, explore the codebase, design modules, then submit a structured PRD to GitHub Issues, Azure DevOps, or a local file.

- **Interview-driven** — relentlessly walks the design tree to reach shared understanding
- **Module design step** *(optional)* — surfaces deep, testable modules before writing the PRD
- **Flexible output** — submits via `gh-cli` skill, `azure-devops-cli` skill, or saves to `./prds/`

```
skills/create-prd/SKILL.md
```

---

### `plan-from-prd`

Turn an approved PRD into a multi-phase local Markdown implementation plan using tracer-bullet vertical slices.

- Identifies **durable architectural decisions** (routes, schema, key models) before slicing
- Each phase is a thin end-to-end slice — demoable and verifiable on its own
- Quizzes the user on granularity and dependencies before writing the file
- Output: `./plans/<feature-name>.md`

> For pushing slices directly to a tracker (GitHub / AzDO / Jira) use `prd-slice` instead.

```
skills/plan-from-prd/SKILL.md
```

---

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

> **Note (Windows / PowerShell):** The generated `.ps1` scripts use `$([char]0x26A0)$([char]0xFE0F)` for the `⚠️` advisory prefix and set `[Console]::OutputEncoding = UTF8` with `ConvertTo-Json -EscapeHandling EscapeNonAscii` (PS 7.1+) to avoid emoji rendering as `??` in some console environments. The templates already include this fix.

```
skills/tool-guard/SKILL.md
skills/tool-guard/references/copilot-cli.md
skills/tool-guard/references/opencode.md
skills/tool-guard/references/claude-code.md
```

---

### `prd-slice`

Break a PRD into independently-deliverable vertical slices (tracer bullets) and create them in Azure DevOps, GitHub Issues, or Jira.

Each slice is a thin end-to-end cut through every layer (schema → API → UI → tests). The skill guides you through drafting slices, quizzing the breakdown with the user, and creating work items in dependency order.

Tracker-specific logic (CLI commands, body templates, linking) is encapsulated in per-tracker reference files — adding a new tracker only requires a new file.

```
skills/prd-slice/SKILL.md
skills/prd-slice/references/azure-devops.md   # AzDO CLI commands + work item template
skills/prd-slice/references/github.md         # gh CLI commands + issue template
skills/prd-slice/references/jira.md           # stub — planned
```

---

### `az-devops-cli`

A comprehensive reference skill for managing Azure DevOps via the `az` CLI. Loaded by other skills (`create-prd`, `prd-slice`) when AzDO is the target tracker — also useful standalone for pipelines, repos, and org administration.

Knowledge is split across focused reference files — the skill reads only what's needed for the current task:

| Reference file | Domain |
|----------------|--------|
| `references/repos-and-prs.md` | Repos, branches, pull requests, branch policies |
| `references/pipelines-and-builds.md` | Pipelines, builds, releases, artifacts |
| `references/boards-and-iterations.md` | Work items, sprints, area paths |
| `references/variables-and-agents.md` | Pipeline variables, variable groups, agent pools |
| `references/org-and-security.md` | Projects, teams, users, permissions, wikis |
| `references/advanced-usage.md` | Output formatting, JMESPath queries |
| `references/workflows-and-patterns.md` | Automation scripts, best practices, error handling |

```
skills/az-devops-cli/SKILL.md
skills/az-devops-cli/references/  # 7 reference files
```

---

### `pre-mortem`

Stress-test a plan before writing a single line of code.

Assumes the plan already failed, then interrogates every branch of the decision tree to surface why — and fix it before you start. Asks hard questions, recommends answers where it can, and outputs a `{project}-design.md`. Never applies changes directly.

```
skills/pre-mortem/SKILL.md
```

---

### `refactoring-plan`

Plan a safe, incremental refactor through user interview and codebase exploration, then submit it as a GitHub issue, Azure DevOps work item, or local file.

- **Alternative strategies** — presents Strangler Fig, Extract-and-Delegate, Parallel Implementation, and other patterns so you choose the right approach for your risk tolerance
- **Thorough interview** — resolves scope, backwards compatibility, blast radius, rollback, and test ownership before a single line changes
- **Test-coverage gate** — checks coverage in the affected area and recommends locking in behavior with tests as the first commit if it's thin
- **Tiny-commit plan** — follows Martin Fowler's advice: every commit leaves the app working and is independently revertable
- **Flexible output** — submits via `gh-cli` skill, `az-devops-cli` skill, or saves to `./plans/`

```
skills/refactoring-plan/SKILL.md
skills/refactoring-plan/evals/evals.json
```

---

### `domain-language`

Build and maintain a shared glossary so everyone on the team — human and AI — uses the same words for the same things.

Extracts terms, roles, and implicit concepts from conversation history and codebase scanning, confirms the list with the user, then writes (or merges into) a `DOMAIN_LANGUAGE.md` at the repo root.

- **Codebase-aware** — scans existing code to align glossary terms with actual naming
- **Confirmation step** — quizzes the user with a mini-dialogue before writing anything
- **Idempotent** — detects an existing glossary file and switches to merge/extend mode
- **Edge cases handled** — thin conversations (< 3 terms) are flagged rather than forced

> Related: `create-prd` (references `DOMAIN_LANGUAGE.md` for naming), `domain-language` can be run at any point in the PRD workflow to lock in terminology.

```
skills/domain-language/SKILL.md
skills/domain-language/evals/evals.json
```

---

### `cleanup-writing`

Edit and improve a piece of writing section by section — fixing information order, improving clarity, and tightening prose — then deliver the full revised document.

- **Dependency-ordered structure** — checks that concepts are introduced before they are relied on; reorders sections that violate this
- **Section confirmation** — presents the proposed structure to the user before rewriting anything
- **240-char paragraph rule** — enforces short paragraphs to reduce cognitive load and keep readers moving
- **Full-document output** — delivers the complete revised document so the user can read the whole as a continuous flow

```
skills/cleanup-writing/SKILL.md
skills/cleanup-writing/evals/evals.json
```

---

### `design-it-twice`

Generate multiple radically different interface designs for a module in parallel, then compare and synthesize the best approach.

Based on *A Philosophy of Software Design* — your first idea is unlikely to be your best. Three sub-agents each receive a different constraint axis (minimize methods / maximize flexibility / optimize for the common case), guaranteeing genuinely different shapes.

- **Parallel sub-agent generation** — 3 designs produced simultaneously, not sequentially
- **Codebase-aware** — explores sibling modules and naming conventions before designing
- **Prose comparison** — trade-off analysis in prose, not tables, to force synthesis over checkbox thinking
- **Synthesis step** — offers to combine the best elements into a hybrid design

```
skills/design-it-twice/SKILL.md
skills/design-it-twice/evals/evals.json
```

---

### `report-issue`

Create a well-structured issue in the appropriate tracking system (GitHub, Azure DevOps, Jira) — whether you're filing a fresh bug report or capturing analysis from `triage-bug`.

- **Context-aware** — if called after `triage-bug`, automatically includes root cause analysis and TDD fix plan in the issue body
- **Tracking system detection** — infers GitHub / AzDO / Jira from project config; asks if ambiguous
- **Graceful fallback** — if no CLI is available, produces a fully-formatted, copyable issue body
- **Metadata guidance** — assigns type, priority, and labels consistent with project conventions
- **Quality-first** — title, steps-to-reproduce, expected vs actual, and acceptance criteria in every issue

```
skills/report-issue/SKILL.md
```

---

### `triage-bug`

Investigate a bug by tracing its root cause through the codebase, then produce a TDD fix plan and file it as a tracked issue.

- **Parallel investigation** — launches subagents for code-path tracing, git history, and pattern comparison simultaneously
- **Root cause, not symptoms** — surfaces the mechanism of failure, not just where it crashed
- **Confidence levels** — honest about uncertainty when investigation is incomplete
- **Durable fix plans** — RED-GREEN cycles describe behaviors and contracts, not file paths or line numbers; plans survive major refactors
- **Integrated handoff** — calls `report-issue` to create the issue; you end up with a URL, a one-line root cause, and a ready-to-execute TDD plan

```
skills/triage-bug/SKILL.md
```

---

### `tdd`

Build features and fix bugs using test-driven development — one red-green cycle at a time, always testing behavior through public interfaces.

- **Codebase-first** — explores the existing test framework, file structure, and prior art before writing a single test
- **Characterization tests** — when adding TDD to existing untested code, locks in current behavior first before touching anything
- **Tracer bullet** — proves infrastructure (runner, imports, assertions) works with one test before building out the full suite
- **Why-driven rules** — the four incremental-loop rules are explained with rationale, not just stated
- **Behavior over implementation** — every step guards against the most common TDD failure mode: tests coupled to internal structure that break on refactors

```
skills/tdd/SKILL.md
skills/tdd/tests.md            # good/bad test examples
skills/tdd/mocking.md          # when and how to mock
skills/tdd/interface-design.md # designing for testability
skills/tdd/deep-modules.md     # small interface, deep implementation
skills/tdd/refactoring.md      # refactor targets
skills/tdd/evals/evals.json
```

---

## Hooks

`hooks/tool-guard/policy.json` is the canonical tool policy for **this repo**. It demonstrates the tool-guard pattern:

- **Warns** on package-manager, task-runner, formatter, linter, and test-runner commands (this is a config-only repo — no install step needed)
- **Denies** destructive git operations (`reset --hard`, `checkout --`, `clean -fd`)

Runtime hook scripts in `.github/hooks/` (Copilot CLI) and `.claude/hooks/` (Claude Code) read this policy on every tool call.

---

## Repo Structure

```
skills/           # Published skills — source of truth
├── adr/
├── az-devops-cli/
├── cleanup-writing/
├── create-prd/
├── design-it-twice/
├── domain-language/
├── plan-from-prd/
├── prd-slice/
├── pre-mortem/
├── refactoring-plan/
├── report-issue/
├── setup-repo/
├── tdd/
├── tool-guard/
└── triage-bug/

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
