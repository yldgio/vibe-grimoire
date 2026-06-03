---
name: playbook-execute
description: >-
  Read a Playbook YAML file and execute its tasks: resolve !include prompts,
  substitute variables, validate schema, topologically sort, then execute
  independent tasks in parallel batches delegating each to the appropriate
  executor (agent or human). Handles on_failure rules (stop/skip/retry/
  fallback), pauses on human executor tasks, and reports progress throughout.
  Trigger when the user says "run playbook", "execute playbook", or provides
  a path to a .yml playbook file.
---

# playbook-execute

Execute a Playbook YAML file end-to-end: resolve `!include` → substitute variables → validate → topological sort → parallel batch execution → success verification → on_failure handling → progress reporting.

---

## Invocation

The developer invokes this skill with a path to a playbook file:

```
run ./playbooks/implement-from-issue.yml
```

If no path is provided, list the `.yml` files in `./playbooks/` and ask the developer which one to run.

---

## Process

### Step 1: Load and parse

Read the YAML file at the given path. If the file does not exist, report a clear error and stop.
If the file exists but cannot be parsed as valid YAML, report the parse error (including line number if available), then stop.

### Step 1.5: Resolve `!include` directives

Before validation, scan every task's `prompt` field for the pattern `!include <path>`. For each one found:

1. Compute the file path: relative to the directory containing the playbook file.
2. Read the referenced file's contents.
3. Replace the `!include <path>` value with the file contents as a multiline string.
4. If the referenced file does not exist: **fatal error** — report clearly (naming the task and the missing file path) and stop without running any tasks.

`!include` is not standard YAML syntax; it is a `playbook-execute` convention resolved entirely at this step. After Step 1.5, no `!include` tokens should remain in any field.

### Step 2: Validate

Before running any task, validate the playbook:

1. **Required top-level fields**: `name`, `description`, `tasks` must be present.
2. **Task required fields**: every task must have `name`, `phase`, `capability`, `prompt`, and `success`.
3. **Unique task names**: no two tasks may share the same `name`.
4. **Phase reference**: each task's `phase` must match a phase `name` declared in `phases` (if `phases` is present). If `phases` is absent, skip this check.
5. **depends_on integrity**: every slug in any `depends_on` list must reference an existing task `name`.
6. **No cycles**: the dependency graph must be a DAG (topologically sortable). If a cycle exists, name every task in the cycle and stop.
7. **capability values**: must be one of `research | implementation | verification | review | decision`. An invalid value is a validation error — stop and report it. (This rule is about validating the `capability` field itself; it does not prohibit executor resolution in Step 4b when capability is valid.)
8. **executor values**: if specified, must be one of `main | explore | code-review | security-review | human | custom:<name>`. An invalid value is a validation error.
9. **on_failure values**: must be one of `stop | skip | retry | fallback:<task-name>`. An invalid value is a validation error.
10. **fallback target exists and is valid**: if `on_failure: fallback:<task-name>`, that task must exist, must not equal the current task, and must not create a fallback loop (A→B→A).
11. **`checks` structural validity**: if a task has a `checks` field, each item must have a valid `type` (`file_exists | file_contains | command | human | agent_confirms`). Required fields per type: `file_exists` → `path`; `file_contains` → `path` + `pattern`; `command` → `run`; `human` → `prompt`; `agent_confirms` → `description`. An invalid or incomplete check item is a validation error.

If validation fails, report every violation clearly, then stop without running any tasks.

### Step 2.5: Collect and substitute variables

If the playbook has a `variables` block:

1. **Collect required values**: for each variable whose default is `""` (empty string), ask the developer to supply a value before execution starts. Present them all at once:
   ```
   This playbook requires the following inputs:
     • issue_url (required): 
     • branch_name (optional, default: "main"):
   ```
2. Merge developer-supplied values with non-empty defaults. Every variable must now have a resolved value.
3. **Substitute** `{{ variables.<name> }}` tokens in every `prompt` and `input` field, replacing them with their resolved values. This substitution happens once, before any task executes.
4. If a `{{ variables.<name> }}` token references a variable not declared in `variables`, treat it as a validation error: report clearly and stop.

If the playbook has no `variables` block, skip this step.

### Step 3: Topological sort

Compute the topological order of all tasks by their `depends_on` relationships. This defines execution eligibility — a task becomes **ready** when all tasks it depends on are `completed` (or satisfied via fallback). Tasks with no `depends_on` are ready immediately.

When multiple tasks are ready at the same time with no dependency between them, they run in **parallel** (see Step 4).

### Step 4: Execute tasks in parallel batches

Use a **frontier-based parallel execution** model:

**Execution loop:**

1. **Compute the ready set**: all tasks whose status is `pending` and whose every `depends_on` entry is `completed` (including satisfied-via-fallback) or `skipped` (see skip propagation below).
2. If the ready set is empty and tasks remain `pending` (blocked by failures): stop — print the final summary.
3. **Launch all ready tasks simultaneously** as background agents. For each task in the ready set, report start and resolve executor (Steps 4a–4b below) before delegating.
4. **Collect completions** as each background task reports back. For each completed task:
   - Verify `success` criteria (Step 4e)
   - Apply `on_failure` if needed (Step 5)
   - Mark the task as `completed` / `skipped` / `failed`
5. After all tasks in the current batch have resolved (each is `completed`, `skipped`, or `failed`): return to step 1.

**Skip propagation**: when a task is `skipped`, any tasks that `depends_on` it are marked `skip-pending`. When the ready set is computed, `skip-pending` tasks are immediately skipped (not launched). Print `⚠️ <task-name> skipped — dependency <dep-name> was skipped.` for each.

**on_failure: stop in a parallel batch**: mark the failing task as `failed`. Allow all other currently-running tasks to complete normally — do not cancel them. Once the batch resolves, print the final summary and stop. Do not launch any further tasks.

#### 4a. Report start

```
▶ [phase: <phase-name>] <task-name>
```

If multiple tasks start simultaneously:
```
▶ [phase: <phase-name>] <task-a>  [parallel]
▶ [phase: <phase-name>] <task-b>  [parallel]
```

#### 4b. Resolve executor

Resolution order:
1. If `executor` is specified and available → use it.
2. If `executor` is unavailable or not specified → find any available agent satisfying `capability` using the capability table below.
3. If no agent satisfies `capability` → pause and ask the developer which agent to use. Their choice applies for the rest of the run.

Availability definition: an executor is **available** if it is a recognized agent in the current IDE session that can receive delegated instructions.

**Default capability → executor table:**

| capability | default executor |
|-----------|-----------------|
| research | explore |
| implementation | main |
| verification | code-review |
| review | code-review |
| decision | human |

#### 4c. Handle `human` executor

When `executor` resolves to `human`:
1. Print a clear separator: `--- 🙋 Human task: <task-name> ---`
2. Display the task's `prompt` verbatim.
3. Wait for the developer's response.
4. Treat the developer's response as the task's output.
5. Print: `--- ✅ Human task complete ---`

> **Parallel note:** a `human` task blocks the batch it is part of until the developer responds. If other tasks in the same batch are agent-run, they may complete before the human responds — their results are held until the human task also resolves.

#### 4d. Delegate to agent executor

For non-human executors, delegate the task to the resolved agent with:
- The task's `prompt` as the instruction (already has `!include` resolved and `{{ variables.x }}` substituted)
- Any `input` artefacts as context
- The `output` field as the expected deliverable

#### 4e. Verify success

After the executor completes, evaluate whether the task's success criteria are met.

**Path A — `checks` present:**

Run each item in the `checks` list in order. For each type:

| Type | Tool action |
|------|------------|
| `file_exists` | Use the View/Read tool to open `path`. Pass if file exists and is non-empty. |
| `file_contains` | Read `path`; search for `pattern` as a substring. Pass if found. |
| `command` | Execute `run` in the terminal. Compare exit code to `expect_exit` (default 0). If `expect_output` is set, verify stdout contains it. |
| `human` | Display `prompt` to the developer. Wait for YES or NO response. NO = fail. |
| `agent_confirms` | Evaluate `description` using LLM judgment. If not confident, count as fail. Report reasoning either way. |

On first failing check: stop evaluating remaining checks. Capture failure evidence:
- **check type** and its identifying field (`path` / `run` / `prompt` / `description`)
- **what was expected** (pattern, exit code, YES confirmation, agent assessment)
- **what was found** (file missing, pattern absent, actual exit code, developer NO, agent reasoning)

Use the captured evidence as the `<reason>` in the failure report and final summary.

If all checks pass: mark the task `completed` (✅).
If any check fails: apply `on_failure` (see Step 5).

---

**Path B — `success` only (no `checks`):**

Apply this priority-ordered judgment protocol. Work through levels in order; stop at the first level that produces a determination:

1. **File mention** — if `success` references a specific filename: use the View/Read tool to check whether the file exists and is non-empty. Verdict is based on the tool result.
2. **Command mention** — if `success` mentions "test passes", "build", "exits 0", or a specific command: attempt to run the described command. If the command is ambiguous, ask the developer for the exact invocation before running. Verdict is based on exit code / output.
3. **Human observable** — if `success` describes something only a person can confirm (e.g., "PR URL returned", "email sent", "developer approved"): display the `success` text to the developer as a confirmation prompt and wait for YES/NO. Never silently pass a human observable.
4. **LLM judgment** — evaluate the `success` text and available evidence with LLM reasoning. Explicitly state the evidence considered. If confidence is below ~70%, ask the developer to confirm rather than silently passing.

On any failure: capture what was checked and what was found. Use as `<reason>` in the failure report.

#### 4f. Report completion

```
✅ [phase: <phase-name>] <task-name> — done
```

### Step 5: Handle `on_failure`

When a task's `success` criteria are not met after execution:

| `on_failure` value | Behaviour |
|-------------------|-----------|
| `stop` (default) | Report the failure with context. Stop the entire playbook. Print the final summary (Step 6). |
| `skip` | Log a warning: `⚠️ <task-name> failed — skipping`. Mark as skipped. Any tasks that `depends_on` this task are also skipped. Continue. |
| `retry` | Re-run the task once. If it fails again, treat as `stop`. |
| `fallback:<task-name>` | Skip this task and run the named fallback task next. Rules: (a) the fallback task must exist and must not be the current task; (b) the fallback task must have all its own `depends_on` already satisfied — if not, stop instead with a clear error; (c) the fallback task runs at most once in this role; (d) if the fallback task itself fails, its own `on_failure` applies. The fallback task's output is treated as the current task's output for downstream `depends_on` checks. |

Concrete fallback example:
- `build-artifact` fails with `on_failure: fallback:restore-artifact`.
- `restore-artifact` runs successfully and produces `artifact.zip`.
- `publish-artifact` depends on `build-artifact`.
- Treat `build-artifact` as satisfied via fallback, using `restore-artifact`'s output as `build-artifact`'s output for downstream checks, so `publish-artifact` can proceed.

### Step 6: Final summary

After all tasks complete (or after a `stop`), print a summary:

```
═══════════════════════════════════════
📋 Playbook run complete: <playbook-name>
═══════════════════════════════════════
✅ Completed  (<n>): <task1>, <task2>, ...
⚠️ Skipped    (<n>): <task3>, ...
❌ Failed     (<n>): <task4> — <reason>
═══════════════════════════════════════
```

If every task completed successfully, add: `🎉 All tasks completed successfully.`

---

## Progress Reporting

Throughout execution, keep the developer informed:

- On each task start: `▶ [<phase>] <task-name>` (append `  [parallel]` when multiple tasks start simultaneously)
- On each task completion: `✅ [<phase>] <task-name> — done`
- On skip: `⚠️ [<phase>] <task-name> — skipped`
- On human task: separator block (see Step 4c)
- On failure before stop: `❌ [<phase>] <task-name> — FAILED: <reason>`
- Between parallel batches: print `--- batch complete, evaluating next tasks ---` when more than one task ran in the last batch

---

## Notes

- **State is maintained within the current conversation.** Execution state (which tasks completed, their outputs) is held in the ongoing agent conversation — it persists across human-executor pauses as long as the conversation continues. It is not written to disk and will be lost if the conversation ends. (Resume-from-task across sessions is Wave 3.)
- **A playbook with no `depends_on` anywhere is valid.** All tasks have no dependencies and launch simultaneously in one parallel batch.
- **Output references:** a task's `output` field describes what it produces. Downstream tasks reference it in their `input` or `prompt`. The executor is responsible for producing it. In a parallel batch, all task outputs are available to the next batch.
- **Wave 3 (deferred):** resume-from-task (re-run from a specific task after partial failure) and run summary artifact (structured report written to disk) are out of scope for this version.
