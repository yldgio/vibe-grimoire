# PRD: PlayBook Skills (`playbook-design` + `playbook-execute`)

## Problem Statement

Agentic skill invocations are isolated: each one is independent. There is no mechanism to compose multiple agent invocations into a single orchestrated workflow. When a complex engineering sequence exists — analyze codebase → write tests → implement → security review → open PR — the developer must manually coordinate every step: remember what the previous step produced, decide when to invoke the next agent, track what has been completed, and re-start from scratch if something fails halfway through.

The orchestration logic lives in the developer's head, not in a versioned, executable artefact. There is no way to declare that task B depends on the output of task A, run C and D in parallel once A is done, or resume from the last completed task after a failure.

## Solution

Two new skills that together form a design-and-execute loop for repeatable agentic workflows:

- **`playbook-design`** — interviews the user about their workflow goals and produces a structured YAML artifact (the *Playbook*) saved in `./playbooks/<name>.yml`.
- **`playbook-execute`** — reads a Playbook and runs its tasks in dependency order, delegating each task to the appropriate executor (agent or human).

A Playbook is a machine-executable workflow graph: a set of named **Phases** (logical groupings expressing intent) each containing **Tasks** (atomic executable units with explicit inputs, outputs, dependencies, and success criteria).

---

## User Stories

### Designing a Playbook

1. As a developer, I want to be interviewed about my workflow goals so that `playbook-design` can produce the YAML structure without me having to know the schema.
2. As a developer, I want to name my playbook and give it a description so that I can identify it at a glance.
3. As a developer, I want to organize tasks into named phases so that the intent and structure of the workflow is clear to anyone reading it.
4. As a developer, I want each task to have a unique slug name so that tasks can reference each other in dependency declarations.
5. As a developer, I want each task to declare a `capability` (research, implementation, verification, review, decision) so that `playbook-execute` can find a suitable executor even when my preferred agent is unavailable.
6. As a developer, I want to specify a preferred `executor` per task so that I can optimize execution for known-good agents.
7. As a developer, I want tasks to declare `depends_on` so that `playbook-execute` sequences them correctly and can run independent tasks in parallel.
8. As a developer, I want to specify `success` criteria per task so that `playbook-execute` can verify completion before advancing to dependent tasks.
9. As a developer, I want to specify `on_failure` behavior per task (stop, skip, retry, fallback) so that I control whether the workflow halts or continues on error.
10. As a developer, I want to declare `input` and `output` per task so that data contracts between tasks are explicit and reviewable.
11. As a developer, I want to write rich task `prompt` content in an external `.md` file and reference it via `!include <path>` so that the YAML graph stays clean.
12. As a developer, I want to declare `variables` at the playbook level (e.g., `issue_url`, `branch_name`) so that a single playbook can be re-run with different inputs.
13. As a developer, I want `playbook-design` to save the result to `./playbooks/<name>.yml` so that it is versioned alongside my codebase.
14. As a developer, I want to see a concrete example Playbook in the skill documentation so that I can write or edit playbooks manually.

### Executing a Playbook

15. As a developer, I want to invoke `playbook-execute` with a path to a Playbook file so that the workflow starts with a single command.
16. As a developer, I want `playbook-execute` to resolve the task execution order by topological sort of `depends_on` so that tasks always run after their dependencies.
17. As a developer, I want `playbook-execute` to run independent tasks in parallel (when their dependencies are all met) so that the workflow completes as fast as possible.
18. As a developer, I want `playbook-execute` to fall back to capability-based executor resolution when my preferred executor is unavailable, so that the workflow doesn't fail due to environment differences.
19. As a developer, I want `playbook-execute` to verify each task's `success` criteria before marking it done, so that downstream tasks don't start on broken outputs.
20. As a developer, I want `playbook-execute` to pause and prompt me for input when a task's executor is `human`, so that approval gates and decision points are honored.
21. As a developer, I want `playbook-execute` to report progress (current phase, running tasks, completed tasks) so that I can follow what's happening.
22. As a developer, I want `playbook-execute` to honour `on_failure` and stop/skip/retry/fallback as configured so that I don't have to babysit every task.
23. As a developer, I want `playbook-execute` to produce a run summary at the end (tasks completed, tasks skipped, failures) so that I have an audit trail.
24. As a developer, I want to be able to re-run a playbook from a specific task (resume after failure) so that I don't have to restart from scratch on partial failures.

---

## Implementation Waves

### Wave 1 (MVP)

Deliver `playbook-design` (full interview → YAML output) and a sequential `playbook-execute` (no parallelism, no resume).

**Done when:** A developer can design a playbook via interview, save it to `./playbooks/`, and execute it end-to-end with tasks run in dependency order. `human` executor pauses work correctly.

### Wave 2

Add parallel execution for independent tasks, `!include` support for external prompts, and playbook-level `variables`.

### Wave 3

Add resume-from-task (partial re-run), run summary artifact, and capability-to-executor resolution rules configurable in the playbook.

---

## Implementation Decisions

### Skill structure

Two sibling skills, each a standalone `SKILL.md`:
- `playbook-design`
- `playbook-execute`

These skills are installed into any developer's agentic environment and operate entirely on **the user's current working repo** — they have no awareness of or dependency on the repo from which they were distributed.

### Artifact location and format

Playbooks are saved as `./playbooks/<name>.yml` in the **user's repo** — pure YAML, no Markdown wrapping. This matches the established pattern for workflow definitions (GitHub Actions, Ansible) and ensures `playbook-execute` can parse them deterministically without LLM interpretation. See `docs/adr/0001-playbook-yaml-format.md`.

### Task schema

```yaml
name: fetch-issue            # slug, kebab-case, unique within playbook — used in depends_on
phase: understand            # name of the containing phase
capability: research         # research | implementation | verification | review | decision
executor: main               # optional preferred agent; falls back to capability resolution
depends_on:                  # optional list of task name slugs
  - some-prior-task
input:                       # optional — artefacts or variables this task receives
  issue_url: "{{ variables.issue_url }}"
output: issue-summary.md     # optional — artefact or state this task produces
prompt: |                    # instructions for the executor (or !include <path>)
  Summarise the issue at {{ input.issue_url }}.
success: |                   # mandatory — observable completion criteria
  issue-summary.md exists and contains problem statement and acceptance criteria
on_failure: stop             # stop | skip | retry | fallback:<task-name> (default: stop)
```

### Playbook-level metadata

```yaml
name: implement-from-issue
description: Analyze a GitHub issue, implement the feature, and open a PR.
version: "1.0"
variables:
  issue_url: ""    # required at runtime
phases:
  - name: understand
    description: Research and plan the implementation
  - name: implement
    description: Write the code
  - name: verify
    description: Review and ship
tasks:
  - ...
```

### Executor resolution

`playbook-execute` resolves executors in this order:
1. Use `executor` if specified and available.
2. Fall back to any agent that satisfies `capability`.
3. If no agent satisfies the capability, pause and ask the developer.

### `!include` syntax

A `prompt` value of `!include prompts/analyze-security.md` causes `playbook-execute` to read the referenced file at runtime and use its content as the prompt. Paths are relative to the playbook file.

### `human` executor

When `executor: human`, `playbook-execute` pauses, displays the task's `prompt` to the developer, and waits for their response before continuing. The developer's response is treated as the task's output.

### Dependency and parallelism

`playbook-execute` topologically sorts tasks. In Wave 1, tasks run sequentially in topological order. In Wave 2, tasks whose dependencies are all satisfied run in parallel via background agents.

---

## Testing Decisions

- **Good tests** verify observable behavior: does `playbook-design` produce a valid YAML file with all required fields? Does `playbook-execute` run tasks in correct dependency order? Does it pause on `human` executor? Does it honour `on_failure: skip`?
- **No implementation detail testing**: do not test the internal parsing logic or executor routing internals — only the skill's visible outputs (files written, tasks run, messages to user).
- **Test approach**: skills are Markdown instruction sets; testing means running the skill end-to-end in an agent session and verifying the output artefacts. Consider adding `evals/` directories (as `the-immortals` does) with example inputs and expected output shapes.

---

## Concrete Example

The following is a complete, valid Playbook file demonstrating all schema features. Use this to validate that the spec above is correct.

**`./playbooks/implement-from-issue.yml`**

```yaml
name: implement-from-issue
description: Analyze a GitHub issue, implement the feature, and open a PR.
version: "1.0"

variables:
  issue_url: ""   # required: the GitHub issue URL (e.g. https://github.com/org/repo/issues/42)

phases:
  - name: understand
    description: Fetch and analyse the issue; explore the codebase.
  - name: implement
    description: Write code that satisfies the acceptance criteria.
  - name: verify
    description: Review for security issues and ship the PR.

tasks:
  - name: fetch-issue
    phase: understand
    capability: research
    executor: main
    input:
      issue_url: "{{ variables.issue_url }}"
    output: issue-summary.md
    prompt: |
      Fetch the GitHub issue at {{ input.issue_url }}.
      Produce issue-summary.md containing:
      - The problem being solved
      - Explicit acceptance criteria (bullet list)
      - Any stated constraints or non-goals
    success: |
      issue-summary.md exists and contains at least one acceptance criterion
    on_failure: stop

  - name: explore-codebase
    phase: understand
    capability: research
    executor: explore
    depends_on:
      - fetch-issue
    input: issue-summary.md
    output: codebase-analysis.md
    prompt: |
      Read issue-summary.md. Explore the codebase to identify:
      - Files most likely to change
      - Existing patterns to follow
      - Integration points relevant to the issue
      Write findings to codebase-analysis.md.
    success: |
      codebase-analysis.md identifies affected files and at least one existing pattern
    on_failure: stop

  - name: approve-plan
    phase: understand
    capability: decision
    executor: human
    depends_on:
      - fetch-issue
      - explore-codebase
    input:
      - issue-summary.md
      - codebase-analysis.md
    prompt: |
      Review issue-summary.md and codebase-analysis.md.
      Reply GO to proceed with implementation, or provide revised acceptance criteria.
    success: Developer replied GO or provided revised criteria
    on_failure: stop

  - name: write-implementation
    phase: implement
    capability: implementation
    executor: main
    depends_on:
      - approve-plan
    input:
      - issue-summary.md
      - codebase-analysis.md
    output: implementation (staged changes in repo)
    prompt: "!include prompts/implement-from-analysis.md"
    success: |
      Code builds without errors.
      All acceptance criteria from issue-summary.md are addressed.
    on_failure: stop

  - name: security-review
    phase: verify
    capability: review
    executor: security-review
    depends_on:
      - write-implementation
    output: security-findings.md
    prompt: |
      Review staged changes for security vulnerabilities.
      Write findings to security-findings.md. If none, write "No findings."
    success: |
      security-findings.md exists.
      No CRITICAL or HIGH severity findings are unresolved.
    on_failure: stop

  - name: open-pr
    phase: verify
    capability: implementation
    executor: main
    depends_on:
      - security-review
    input:
      - issue-summary.md
      - security-findings.md
    prompt: |
      Open a GitHub PR for the staged changes.
      - Title: derived from issue-summary.md
      - Body: summary of changes + reference to the issue URL + any security findings addressed
    success: PR URL returned and accessible
    on_failure: stop
```

---

## Out of Scope

- **Scheduling / cron**: playbooks are manually invoked, not time-triggered.
- **Cross-repo playbooks**: playbooks run in the context of a single repo.
- **Playbook versioning / registry**: no central registry; playbooks live in the repo that uses them.
- **Visual workflow editor**: the design interface is the `playbook-design` skill interview, not a GUI.
- **Secret management**: the playbook schema does not handle credentials; those are expected in the environment.
- **Rollback**: `playbook-execute` does not undo completed tasks on downstream failure; rollback is the developer's responsibility.

---

## Further Notes

- The `!include` syntax is a convention interpreted by `playbook-execute`. It is not standard YAML; the skill must resolve it at parse time.
- `variables` declared in the playbook metadata are substituted into `prompt` and `input` fields using `{{ variables.<name> }}` syntax (Mustache-style). The exact templating syntax should be consistent across both skills.
- A playbook with no `depends_on` declarations anywhere is valid: tasks run in the order they appear in the file.
- The `on_failure: fallback:<task-name>` value means: if this task fails, run the named task instead and continue from there. The fallback task must exist in the same playbook.
