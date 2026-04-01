# code-skills

> Reusable agentic skills, hooks, and policies for AI-augmented ("vibe") coding.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-26-blue)](#skills)

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

### `adversarial-review`

Launch a multi-model adversarial review panel to stress-test code, architecture, PRDs, pull requests, or documentation — before a flaw becomes a production incident.

Three specialized reviewers run in parallel, each powered by a different AI model and assigned a distinct attack vector:

| Reviewer | Model | Attack Vector |
|----------|-------|---------------|
| 🔴 **The Skeptic** | GPT-5.4 | Challenges the fundamental design — *"Why this approach at all?"* |
| ⚡ **The Executioner** | Claude Sonnet 4.6 | Hunts failure modes, edge cases, and correctness issues |
| 🔨 **The Pragmatist** | GPT-5.3-Codex | Attacks real-world viability — maintainability, operability, hidden costs |

- **Automatic scaling** — simple tasks get a gentle pushback ("is this really worth a full panel?"); medium tasks use 1–2 reviewers; complex tasks (system designs, large PRs, cross-cutting changes) use all 3
- **Convergence detection** — issues flagged independently by multiple reviewers are surfaced as near-certainties
- **Explicit dissents** — genuine conflicts between reviewers are preserved, not collapsed into false consensus
- **Verdict** — every review ends with 🔴 DO NOT PROCEED / 🟡 CONDITIONAL / 🟢 PROCEED WITH CAUTION

Pairs naturally with `pre-mortem` (stress-test designs before building) and feeds into `refactoring`, `design-patterns`, `tdd`, or `clean-code` for remediation.

```
skills/adversarial-review/SKILL.md
skills/adversarial-review/evals/evals.json
```

---

### `techdebt`

Audit a codebase for technical debt: find and remove duplicated code, dead code, god objects, overly complex functions, and inconsistent patterns — prioritized by impact, executed with the smallest safe changes possible.

- **7 debt categories** — duplication, dead code, god objects, deep nesting, magic values, inconsistent patterns, overly complex functions
- **Prioritized inventory** — groups findings by severity (🔴 Critical / 🟡 Moderate / 🟢 Minor) before touching anything
- **Duplication-aware consolidation** — identifies the canonical version, checks whether copies have diverged, reconciles differences before merging
- **Safe dead-code deletion** — verifies code is truly unreachable (checks dynamic imports, string-based lookups) before removing
- **Scope guarantee** — delivers a cleanup summary and returns control; does not drift into architectural refactors (those belong in `refactoring-plan`)

**Skill workflow** — chains naturally with:
`refactoring-plan` *(plan the larger structural changes)* → `techdebt` *(execute the cleanup)* → `tdd` *(lock in behavior with tests before removing debt)*

```
skills/techdebt/SKILL.md
skills/techdebt/evals/evals.json
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

### Data Contracts

---

### `data-normalization`

Establish a Canonical Data Model for a project — define authoritative format rules for each primitive type, map every external data source to the canonical form, generate adapter / validator code, and record decisions in an ADR.

- **Type-first workflow** — walks through all primitive types (dates, strings, decimals, identifiers, enums, booleans, null semantics) and confirms a rule for each before writing anything
- **ISO 8601 + explicit timezone** — recommends and enforces UTC-offset timestamps; flags lossy transformations (e.g., local-time sources with no offset) as data quality issues
- **No floats for money** — proposes integer minor units or explicit-scale Decimal; generates validators that reject IEEE 754 floats at the ingestion boundary
- **Field mapping tables** — per-source tables showing source field → canonical field, type coercion, transformation rule, and round-trip loss risk
- **Adapter / validator code generation** — generates code in the project's target language using existing validation libraries (zod, pydantic, joi) where available
- **ADR integration** — calls the `adr` skill to document why these formats were chosen and what was rejected

```
skills/data-normalization/SKILL.md
skills/data-normalization/references/type-standards.md  # ISO 8601, UTF-8, IEEE 754, UUID guidance
skills/data-normalization/evals/evals.json
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

## The Immortals

Six skills that encode the most influential voices in software engineering — and an orchestrator that routes to the right expert(s) automatically.

### `design-patterns`

Identify the right GoF or enterprise pattern for a problem, apply it with minimal disruption, and detect when patterns are misapplied or forced.

- **Full catalog coverage** — GoF creational, structural, behavioral + Fowler's enterprise application patterns (Repository, Unit of Work, Service Layer, etc.)
- **Pattern recognition** — reads existing code structure and signals which patterns are present, absent, or misidentified
- **Fit evaluation** — asks whether the problem justifies the abstraction before recommending a pattern
- **Misuse detection** — flags Pattern Astronaut disease, Singleton abuse, wrong-dimension variation
- **Integrates with** `refactoring` (prepare the ground) → **`design-patterns`** (apply) → `adr` (record the decision)

```
skills/design-patterns/SKILL.md
```

---

### `clean-code`

Systematically audit code for naming honesty, function shape, class cohesion, and SOLID violations — making code readable for every future reader.

- **Naming audit** — checks every function, class, and variable name for truth, specificity, and vague evasions (`Manager`, `Helper`, `Handler`)
- **SOLID analysis** — checks SRP, OCP, LSP, ISP, DIP with specific signals for each violation
- **Function shape review** — size, abstraction levels, argument count; flags mixed-level functions and long argument lists
- **Comment hygiene** — removes comments that repeat the code; keeps those that explain *why*

```
skills/clean-code/SKILL.md
```

---

### `refactoring`

Apply specific, named, behavior-preserving refactoring moves — one at a time, with tests passing before and after each move.

- **Named moves from Fowler's catalog** — Extract Method, Inline Method, Introduce Parameter Object, Replace Conditional with Polymorphism, Move Method/Field, and more
- **Safety discipline** — verifies tests are green before each move; reverts immediately if tests break after
- **Atomic commits** — each move is one commit; rollback is always trivial
- **Distinct from `refactoring-plan`** — this skill *executes* specific moves; use `refactoring-plan` to choose the overall strategy

```
skills/refactoring/SKILL.md
```

---

### `domain-driven-design`

Model complex domains using Evans's strategic and tactical DDD: bounded contexts, context maps, aggregates, domain events, and ubiquitous language.

- **Strategic design** — identifies core, supporting, and generic domains; maps bounded contexts and names integration patterns (ACL, Partnership, Conformist, Open Host Service, etc.)
- **Tactical design** — models aggregates, entities, value objects, domain events, repositories, and domain services within each context
- **Ubiquitous language enforcement** — surfaces the translation tax when code and domain experts use different words
- **Anti-pattern detection** — flags anemic domain models, god aggregates, leaking bounded contexts, and premature CQRS/Event Sourcing

```
skills/domain-driven-design/SKILL.md
```

---

### `performance-review`

Identify where code is actually slow, why it's slow, and what the minimum intervention is to fix it — never optimizes without measuring.

- **Complexity analysis** — Big O reasoning for algorithmic problems before profiling; flags O(n²) in hot paths, linear searches, unmoized recursion
- **I/O and N+1 detection** — identifies the most common database performance failure; recommends batching, eager loading, caching at the right level
- **Memory and concurrency** — allocation patterns, GC pressure, lock contention, critical section granularity
- **Profiling strategy** — ecosystem-specific tooling (cProfile, py-spy, pprof, async-profiler, EXPLAIN ANALYZE) and the measure-first discipline

```
skills/performance-review/SKILL.md
```

---

### `the-immortals`

Orchestrate the five legendary developer personas — routing tasks to the right specialist(s) and synthesizing their perspectives into a clear recommendation.

- **Automatic routing** — classifies tasks as 🟢 Solo (one specialist), 🟡 Duo (two domains intersect), or 🔴 Full Council (architectural or cross-cutting scope)
- **Direct overrides** — `@fowler`, `@beck`, `@uncle-bob`, `@evans`, `@linus` bypass routing and go straight to the named member
- **Structured council format** — each member speaks in their own voice, then a Synthesis surfaces the majority view and named Dissents preserve real disagreements
- **Linus always joins Full Council** — devil's advocacy is his standing role

```
skills/the-immortals/SKILL.md
```

---

## Agents

The Immortals are five legendary developer personas — Martin Fowler, Kent Beck, Robert C. Martin, Eric Evans, and Linus Torvalds — plus an orchestrator that routes tasks to the right expert or convenes a full council. Each agent has a distinct voice, specialty, and set of skills it invokes.

Install once with the scripts below. Then invoke any agent by alias in your Copilot CLI chat.

| Agent | Alias | Specialty | Persona |
|-------|-------|-----------|---------|
| Martin Fowler | `@fowler` | Design patterns, refactoring, enterprise architecture | Precise, catalog-driven |
| Kent Beck | `@beck` | TDD, XP, simplicity | Direct, test-first |
| Robert C. Martin | `@uncle-bob` | Clean Code, SOLID, OOP | Didactic, principled |
| Eric Evans | `@evans` | Domain-Driven Design, ubiquitous language | Strategic, domain-fluent |
| Linus Torvalds | `@linus` | Performance, systems, code review | Blunt, performance-obsessed |
| The Immortals | `@the-immortals` | Orchestrator — Solo / Duo / Full Council | Routes by complexity |

### Usage

**Single expert:**
```
@fowler review this service layer for coupling violations
```

**Orchestrator (routes automatically):**
```
@the-immortals we're seeing N+1 queries in our checkout flow
```

**Full council (append `—full council`):**
```
@the-immortals review this auth module — full council
```

### Install

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/install-immortals.sh)
```

**Windows (PowerShell):**
```powershell
iex (iwr -UseBasicParsing https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/install-immortals.ps1).Content
```

For Claude Code and OpenCode, see [docs/installing-agents.md](docs/installing-agents.md).

---

## Hooks

`hooks/tool-guard/policy.json` is the canonical tool policy for **this repo**. It demonstrates the tool-guard pattern:

- **Warns** on package-manager, task-runner, formatter, linter, and test-runner commands (this is a config-only repo — no install step needed)
- **Denies** destructive git operations (`reset --hard`, `checkout --`, `clean -fd`)

Runtime hook scripts in `.github/hooks/` (Copilot CLI) and `.claude/hooks/` (Claude Code) read this policy on every tool call.

---

## Extensions

Copilot CLI extensions live in `.github/extensions/<name>/extension.mjs` (project-level, active only in this repo) or `~/.copilot/extensions/<name>/extension.mjs` (user-level, always active).

### `notify` *(Windows only)*

Gives agents two tools for alerting you at the end of long tasks — without requiring you to watch the screen.

| Tool | What it does |
|------|-------------|
| `notify_speak(text, language?)` | Reads text aloud via Windows SAPI (Text-To-Speech). Pass the BCP-47 language tag (e.g. `it-IT`, `en-US`) so the right voice is selected. |
| `notify_toast(title, message)` | Shows a balloon notification in the Windows system tray. Stays for ~5 s then disposes itself. |

**Requirements:** Windows · Node.js ≥ 18 · no extra installs (uses built-in .NET assemblies `System.Speech` + `System.Windows.Forms`)

**Install — project-level** (active only inside this repo):

Already included — no action needed if you cloned this repo. To add it to another project, copy the file:

```bash
# macOS / Linux
mkdir -p .github/extensions/notify
cp /path/to/vibe-grimoire/.github/extensions/notify/extension.mjs \
   .github/extensions/notify/

# Windows
mkdir .github\extensions\notify
copy path\to\vibe-grimoire\.github\extensions\notify\extension.mjs ^
     .github\extensions\notify\
```

**Install — user-level** (available in every project, always):

```bash
# macOS / Linux
mkdir -p ~/.copilot/extensions/notify
cp .github/extensions/notify/extension.mjs ~/.copilot/extensions/notify/

# Windows (PowerShell)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.copilot\extensions\notify"
Copy-Item .github\extensions\notify\extension.mjs `
          "$env:USERPROFILE\.copilot\extensions\notify\"
```

Then reload: type `/clear` inside a Copilot CLI session, or restart the terminal.

> **⚠️ Platform note:** `notify_speak` and `notify_toast` use Windows-only .NET assemblies (`System.Speech`, `System.Windows.Forms`). The extension loads on macOS/Linux but the tools will return an error at runtime. Cross-platform support (macOS `say`, Linux `espeak` / `notify-send`, OpenCode plugin) is planned.

```
.github/extensions/notify/extension.mjs   # extension source
.github/extensions/notify/README.md       # full reference with security notes
```

---

## Repo Structure

```
skills/           # Published skills — source of truth
├── adversarial-review/
├── adr/
├── az-devops-cli/
├── boris/
├── cleanup-writing/
├── clean-code/
├── create-prd/
├── data-normalization/
├── design-it-twice/
├── design-patterns/
├── domain-driven-design/
├── domain-language/
├── kaizen/
├── performance-review/
├── plan-from-prd/
├── prd-slice/
├── pre-mortem/
├── refactoring/
├── refactoring-plan/
├── report-issue/
├── setup-repo/
├── tdd/
├── techdebt/
├── the-immortals/
├── tool-guard/
└── triage-bug/

.github/
├── agents/       # The Immortals persona agents
└── extensions/   # Copilot CLI extensions
    └── notify/   # TTS + system tray notifications (Windows)

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
