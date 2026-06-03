# Plan: PlayBook Skills (`playbook-design` + `playbook-execute`)

> Source PRD: `prds/playbook-skills.md`

## Architectural decisions

Durable decisions that apply across all phases:

- **Skill format**: Each skill is a standalone `SKILL.md` with YAML frontmatter. `description` field ≤ 900 characters (kaizen constraint).
- **Skill location**: `skills/playbook-design/SKILL.md` and `skills/playbook-execute/SKILL.md`.
- **Playbook artifact**: `./playbooks/<name>.yml` in the user's repo — pure YAML, no Markdown wrapper.
- **Task schema** (locked):
  - `name` — kebab-case slug, unique within playbook, used as identifier in `depends_on`
  - `phase` — name of containing phase
  - `capability` — `research | implementation | verification | review | decision`
  - `executor` — optional preferred agent; falls back to capability resolution
  - `depends_on` — optional list of task name slugs
  - `input` — optional artefacts/variables received
  - `output` — optional artefact/state produced
  - `prompt` — executor instructions, or `!include <relative-path>` (Wave 2)
  - `success` — mandatory observable completion criteria
  - `on_failure` — `stop | skip | retry | fallback:<task-name>` (default: `stop`)
- **Executor values**: `main | explore | code-review | security-review | human | custom:<name>`
- **Executor resolution order**: explicit `executor` → capability fallback → pause and ask developer
- **Templating** (Wave 2): `{{ variables.<name> }}` Mustache-style in `prompt` and `input` fields
- **`!include` syntax** (Wave 2): resolved at parse time by `playbook-execute`; path is relative to the playbook file
- **Evals pattern**: `evals/` directory per skill with example inputs and expected outputs (same as `skills/the-immortals/evals/`)
- **Scope boundary**: both skills operate on the user's current working repo; they have no awareness of vibe-grimoire or any distribution repo

---

## Wave 1: MVP

> Done when: a developer can design a playbook via interview, save it to `./playbooks/`, and execute it end-to-end with tasks run in dependency order. `human` executor pauses correctly.

## Phase 1: `playbook-design` skill

**User stories**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14

### What to build

Write `skills/playbook-design/SKILL.md`. The skill interviews the user about their workflow goals and produces a valid Playbook YAML file, saved to `./playbooks/<name>.yml`.

The skill must:
- Open with a structured interview that elicits: playbook name, description, phases, tasks (with all schema fields for each)
- Validate during the interview that: task `name` values are kebab-case and unique, `depends_on` references exist, `success` is present on every task
- Produce a complete, valid YAML artifact matching the locked schema
- Save to `./playbooks/<name>.yml`
- Include the `implement-from-issue.yml` concrete example from the PRD in the skill documentation so developers can write or edit playbooks manually

Add `skills/playbook-design/evals/` with at least one eval: a sample interview transcript as input and the expected YAML output shape.

### Acceptance criteria

- [ ] `skills/playbook-design/SKILL.md` exists with valid YAML frontmatter (`name`, `description` ≤ 900 chars)
- [ ] Skill instructions cover the full interview → YAML → save flow
- [ ] Instructions specify validation rules: unique slugs, depends_on integrity, success field required
- [ ] Concrete example (`implement-from-issue.yml`) is embedded or linked in the skill doc
- [ ] `evals/` directory exists with at least one input/output example pair

---

## Phase 2: `playbook-execute` skill (sequential)

**User stories**: 15, 16, 18, 19, 20, 21, 22

### What to build

Write `skills/playbook-execute/SKILL.md`. The skill reads a Playbook YAML file and executes its tasks sequentially in topological dependency order.

Wave 1 scope (no parallelism, no `!include`, no variable substitution):
- Parse the YAML file; validate it against the schema before starting
- Topologically sort tasks by `depends_on`; detect and reject cycles
- Run tasks one at a time in sorted order, delegating each to its `executor`
- Capability fallback: if `executor` is unavailable, find any agent satisfying `capability`; if none, pause and ask the developer
- `human` executor: display the task `prompt` to the developer and wait for their response as the task output
- After each task: verify `success` criteria; if not met, apply `on_failure` (stop / skip / retry once / fallback to named task)
- Report progress throughout: current phase, task name, status
- On completion: report which tasks completed, which were skipped, which failed

Add `skills/playbook-execute/evals/` with at least one eval: a sample playbook YAML as input and the expected execution trace as output.

### Acceptance criteria

- [ ] `skills/playbook-execute/SKILL.md` exists with valid YAML frontmatter (`name`, `description` ≤ 900 chars)
- [ ] Skill instructions cover: parse → validate → topological sort → sequential execution → success check → on_failure → progress report
- [ ] `human` executor pause behaviour is explicitly specified
- [ ] Capability fallback resolution is explicitly specified
- [ ] All four `on_failure` values are handled: `stop`, `skip`, `retry`, `fallback:<task>`
- [ ] `evals/` directory exists with at least one playbook → execution trace example

---

## Wave 2: Full power

> Phases 3 and 4 share no blocking dependencies and can proceed in parallel.

## Phase 3: Variables + `!include`

**User stories**: 11, 12

### What to build

Update both skills to support playbook-level variables and external prompt files.

**`playbook-design`** changes:
- Add a step in the interview to elicit `variables` — ask the developer what runtime inputs the playbook needs, their names, and default values (empty string if required)
- Include `variables` in the generated YAML output

**`playbook-execute`** changes:
- Before execution, collect any `variables` whose default is empty (required inputs) from the developer
- Substitute `{{ variables.<name> }}` in `prompt` and `input` fields before delegating to the executor
- At YAML parse time, resolve `!include <path>` by reading the referenced file (path relative to the playbook file) and substituting its content as the `prompt` value

### Acceptance criteria

- [ ] `playbook-design` interview elicits `variables` and includes them in the output YAML
- [ ] `playbook-execute` prompts for required variables (empty default) before starting execution
- [ ] `{{ variables.<name> }}` is substituted in `prompt` and `input` before task delegation
- [ ] `!include <path>` is resolved at parse time; missing file is a fatal error with a clear message
- [ ] Eval examples updated or added to cover a playbook with variables and an `!include`

---

## Phase 4: Parallel execution

**User story**: 17

### What to build

Update `playbook-execute` to detect and run independent tasks in parallel when all their dependencies are satisfied.

- After each task completes, re-evaluate which tasks are now unblocked (all `depends_on` satisfied)
- Launch all newly unblocked tasks as background agents simultaneously
- Wait for all running tasks before evaluating the next frontier
- Merge outputs: each parallel task's `output` is available to downstream tasks that declare it in `depends_on`
- `on_failure` in a parallel task still applies; if one parallel task fails with `stop`, running siblings are noted but not cancelled (they complete then execution halts)

### Acceptance criteria

- [ ] `playbook-execute` instructions describe the parallel execution model
- [ ] Tasks with no unsatisfied dependencies run concurrently
- [ ] Outputs from parallel tasks are individually accessible to downstream tasks
- [ ] `on_failure: stop` in a parallel task halts the playbook after current parallel batch completes
- [ ] Eval example added demonstrating a playbook with independent parallel tasks

---

## Wave 3 — Deferred

The following are out of scope for this plan and will be addressed in a future planning pass:

- **Resume-from-task** (US 24): re-run a playbook starting from a specific task after partial failure
- **Run summary artifact** (US 23): structured end-of-run report written to disk
- **Configurable capability→executor rules**: playbook-level override of the default capability resolution table
