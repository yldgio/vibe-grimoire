---
name: playbook-execute
description: >-
  Read a Playbook YAML file and execute its tasks in topological dependency
  order, delegating each to the appropriate executor (agent or human).
  Validates the playbook before starting, resolves executors by capability
  fallback, honours on_failure rules (stop/skip/retry/fallback), pauses on
  human executor tasks, and reports progress throughout. Trigger when the
  user says "run playbook", "execute playbook", or provides a path to a
  .yml playbook file. Wave 1: sequential execution only.
---

# playbook-execute

Execute a Playbook YAML file end-to-end: parse → validate → topological sort → sequential execution → success verification → on_failure handling → progress reporting.

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

If validation fails, report every violation clearly, then stop without running any tasks.

### Step 3: Topological sort

Sort the task list so that every task appears after all tasks it `depends_on`. Use Kahn's algorithm or depth-first post-order. Tasks with no dependencies come first. When multiple tasks are unblocked at the same level, maintain their file order.

### Step 4: Execute tasks sequentially

Work through the sorted task list one at a time. For each task:

Before executing a task, check whether any task in its `depends_on` list is marked as skipped. If so, skip this task too and print:

`⚠️ <task-name> skipped — dependency <dep-name> was skipped.`

Then continue to the next task.

#### 4a. Report start

```
▶ [phase: <phase-name>] <task-name>
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

#### 4d. Delegate to agent executor

For non-human executors, delegate the task to the resolved agent with:
- The task's `prompt` as the instruction
- Any `input` artefacts as context
- The `output` field as the expected deliverable

#### 4e. Verify success

After the executor completes, evaluate whether the `success` criteria are met. The `success` field describes an observable state — check it:
- File exists → verify the file is present and non-empty
- Test passes → confirm the build/test output shows passing
- Developer responded → the human response counts as success
- Any other description → use judgment; when uncertain, ask the developer to confirm

If `success` is met: mark the task ✅ and proceed.
If `success` is not met: apply `on_failure` (see Step 5).

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

- On each task start: `▶ [<phase>] <task-name>`
- On each task completion: `✅ [<phase>] <task-name> — done`
- On skip: `⚠️ [<phase>] <task-name> — skipped`
- On human task: separator block (see Step 4c)
- On failure before stop: `❌ [<phase>] <task-name> — FAILED: <reason>`

---

## Wave 2 features (not yet active)

The following features are defined but **not active in Wave 1**. When you encounter them, warn the developer and document the behavior:

- **`variables` block at playbook level**: If the playbook contains a `variables` section, warn the developer: *"This playbook declares variables. Variable substitution is a Wave 2 feature — `{{ variables.<name> }}` tokens will be passed to executors as-is in Wave 1."* Do not collect or substitute variables. Proceed with raw token text in all fields.
- **`!include <path>`** in `prompt`: If you encounter `!include <path>` in any `prompt` field, warn: *"`!include` is a Wave 2 feature — the executor will receive the literal text `!include <path>` as its prompt in Wave 1."* Do not read the referenced file.

> **Note for Wave 2 implementors:** Activate variable substitution by collecting all `variables` values (prompting for any with an empty default) before execution, then substituting `{{ variables.<name> }}` in all `prompt` and `input` fields. Activate `!include` by reading the referenced file (path relative to the playbook file) and substituting its content as the `prompt` value at parse time.

---

## Notes

- **State is maintained within the current conversation.** Execution state (which tasks completed, their outputs) is held in the ongoing agent conversation — it persists across human-executor pauses as long as the conversation continues. It is not written to disk and will be lost if the conversation ends. (Resume-from-task across sessions is Wave 3.)
- **A playbook with no `depends_on` anywhere is valid.** Tasks run in file order.
- **Output references:** a task's `output` field describes what it produces. Downstream tasks reference it in their `input` or `prompt`. The executor is responsible for producing it.
- **Parallel execution is Wave 2.** All tasks run sequentially in Wave 1.
