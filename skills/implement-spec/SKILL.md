---
name: implement-spec
description: >-
  Autonomously implement a specification produced by the specify skill. Reads
  the spec document, builds a task queue in the session database, implements
  tasks in parallel where dependencies allow, runs deterministic checks, spawns
  adversarial verification (different model), and iterates until all evaluation
  criteria pass or convergence is reached. Use when the user has a spec document
  (from the specify skill or a similar structured spec) and wants it implemented
  with guaranteed quality verification. Trigger phrases: "implement this spec",
  "build this", "execute the spec", "implement-spec", "start implementation",
  "make it happen", or when the user points to a ./specs/*.md file and asks to
  build it. Also use when the user has just finished using specify and says
  "now build it", "go", or "implement".
---

# Implement Spec

Autonomously implement a specification document, using the session database as the source of truth for progress, and adversarial multi-model verification to guarantee quality.

**Skill workflow:**
[`the-goal`](#) → [`specify`](#) → **`implement-spec`** → done

---

## Prerequisites

- A spec document (typically `./specs/<name>.md`) produced by `specify` or following the same structure
- The spec must contain:
  - **Task Breakdown** with inline Definition of Done and Evaluation criteria per task (new format)
    - OR tasks with aggregate Evaluation Criteria tables (old format)
  - **Evaluation Criteria** (deterministic checks + LLM-as-judge) either inline per task or in aggregate tables
  - **Verification Protocol** defining adversarial verification
  - **Convergence** rules defining when to stop iterating
- Each task must have:
  - **Definition of Done** ("Done when:" field) — observable completion criterion
  - **Evaluation criteria** (inline or in aggregate tables) — at least one deterministic check or LLM-as-judge criterion

---

## Phase 0: Initialize

### Check for existing state

Query the session database:

```sql
SELECT name FROM sqlite_master WHERE type='table' AND name='spec_tasks';
```

- **If table exists** → resume from current state. Skip to Phase 2.
- **If table does not exist** → proceed to parse the spec and create the schema.

### Parse the spec

Read the spec document. Extract:

1. **Tasks** — each task from the Task Breakdown section: ID, title, description, dependencies, **definition of done (DoD)**, and **inline evaluation criteria**
   - **DoD extraction**: Look for the "Done when:" field in each task. This is the observable completion criterion.
   - **Inline evaluation extraction**: Look for the "Evaluation:" section in each task. Parse:
     - **Deterministic check**: command/test → expected result
     - **LLM-as-judge**: aspect → 1-5 scale → Pass ≥ N (if present)
   - **Fallback**: If inline evaluation is missing, fall back to the aggregate Evaluation Criteria tables (for backward compatibility with old spec format)
   
2. **Deterministic checks** — prioritize inline "Evaluation > Deterministic check" from each task; if absent, fall back to the aggregate Evaluation Criteria table
3. **LLM-as-judge criteria** — prioritize inline "Evaluation > LLM-as-judge" from each task; if absent, fall back to the aggregate table
4. **Convergence rules** — quality floor, diminishing returns threshold, max iterations (from Convergence section)
5. **Adversarial protocol** — who verifies, how (from Verification Protocol section)

**Parsing strategy:**
- For each task, first check for inline "Done when:" and "Evaluation:" fields (new format)
- If inline evaluation is missing or incomplete, query the aggregate Evaluation Criteria tables
- Store both DoD and evaluation criteria per task in the database
- Warn if a task has no DoD or no evaluation criteria after both extraction attempts

### Backward compatibility

**Old spec format** (aggregate-only):
```markdown
### Task 1: Name
- **Depends on**: none
- **Description**: what to do

## Evaluation Criteria
### Deterministic Checks
| Check | Task | How to run | Pass condition |
| check-1 | Task 1 | npm test | All tests pass |
```

**New spec format** (inline + aggregate):
```markdown
### Task 1: Name
- **Depends on**: none
- **Description**: what to do
- **Done when**: Observable completion criterion
- **Evaluation**: 
  - **Deterministic check**: npm test → All tests pass
  - **LLM-as-judge**: Error messages → 1-5 clarity scale → Pass ≥ 4
```

**Parsing logic:**
1. Try to extract inline `Done when:` and `Evaluation:` from the task
2. If inline evaluation is absent or incomplete, fall back to aggregate tables
3. Map aggregate table entries to the task by matching the "Task" column
4. Store the merged result in `spec_tasks` table

**Example extraction code (pseudocode):**
```
for each task in spec:
  done_when = extract_field(task, "Done when:")
  inline_checks = extract_field(task, "Evaluation: > Deterministic check:")
  inline_judges = extract_field(task, "Evaluation: > LLM-as-judge:")
  
  if inline_checks is empty:
    inline_checks = query_aggregate_table("Deterministic Checks", task_id)
  
  if inline_judges is empty:
    inline_judges = query_aggregate_table("LLM-as-Judge Criteria", task_id)
  
  insert_into_db(task_id, done_when, inline_checks, inline_judges)
```

### Create the session schema

```sql
CREATE TABLE IF NOT EXISTS spec_tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  done_when TEXT,
  depends_on TEXT DEFAULT '[]',
  status TEXT DEFAULT 'pending',
  attempt INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  deterministic_checks TEXT DEFAULT '[]',
  llm_judge_criteria TEXT DEFAULT '[]',
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS verification_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL,
  attempt INTEGER NOT NULL,
  check_type TEXT NOT NULL,
  check_name TEXT NOT NULL,
  passed INTEGER NOT NULL,
  score REAL,
  evidence TEXT,
  issues TEXT,
  verified_by TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS iteration_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT,
  iteration INTEGER NOT NULL,
  action TEXT NOT NULL,
  rationale TEXT,
  improvement_delta REAL,
  created_at TEXT DEFAULT (datetime('now'))
);
```

**Schema updates:**
- Added `done_when` field to store the Definition of Done per task (extracted from "Done when:" field)
- Added `llm_judge_criteria` field to store LLM-as-judge criteria as JSON array (extracted from inline "Evaluation > LLM-as-judge")
- Both `deterministic_checks` and `llm_judge_criteria` are stored as JSON for structured querying

### Populate tasks

Insert each task from the spec into `spec_tasks`:

- **Task fields**: id, title, description, done_when, depends_on, deterministic_checks, llm_judge_criteria
- **done_when**: Extract from "Done when:" field in each task (mandatory in new format)
- **depends_on**: JSON array of task IDs from "Depends on:" field
- **deterministic_checks**: JSON array of check objects extracted from inline "Evaluation > Deterministic check"
  - Each object: `{name, command, pass_condition}`
  - Fallback: If inline is missing, query the aggregate Evaluation Criteria > Deterministic Checks table
- **llm_judge_criteria**: JSON array of judge objects extracted from inline "Evaluation > LLM-as-judge"
  - Each object: `{name, question, evidence, scale, pass_threshold}`
  - Fallback: If inline is missing, query the aggregate Evaluation Criteria > LLM-as-Judge Criteria table

**Example INSERT:**

```sql
INSERT INTO spec_tasks (id, title, description, done_when, depends_on, deterministic_checks, llm_judge_criteria)
VALUES (
  'task-1',
  'Implement user authentication',
  'Add JWT-based authentication to the API',
  'A user can log in with email/password and receive a JWT token that grants access to protected endpoints',
  '[]',
  '[{"name": "auth-test-passes", "command": "npm test -- auth.test.js", "pass_condition": "All tests pass with exit code 0"}]',
  '[{"name": "error-message-quality", "question": "Does the error message explain what went wrong and how to fix it?", "evidence": "Read all error messages produced by the auth module", "scale": "1–5 scale where 5 = message explains cause, consequence, and fix action", "pass_threshold": 4}]'
);
```

**Validation after population:**
- Query for tasks with missing DoD: `SELECT id, title FROM spec_tasks WHERE done_when IS NULL OR done_when = '';`
- Query for tasks with no evaluation criteria: `SELECT id, title FROM spec_tasks WHERE (deterministic_checks = '[]' OR deterministic_checks IS NULL) AND (llm_judge_criteria = '[]' OR llm_judge_criteria IS NULL);`
- Warn the user if any tasks are missing critical fields

### Mark ready tasks

```sql
UPDATE spec_tasks SET status = 'ready'
WHERE status = 'pending'
AND NOT EXISTS (
  SELECT 1 FROM spec_tasks dep
  WHERE dep.id IN (SELECT value FROM json_each(spec_tasks.depends_on))
  AND dep.status != 'passed'
);
```

---

## Phase 1: Explore the codebase

Before implementing anything, use a subagent to explore the current codebase:

- Existing architecture and patterns
- Test framework and conventions
- Relevant modules that will be modified
- Any constraints or decisions from the spec's "Decisions Already Made" section that need verification

This exploration informs implementation approach but does NOT change the spec. If exploration reveals a wrong assumption, escalate to the user before proceeding.

---

## Phase 2: Implementation loop

This is the core autonomous loop. Repeat until all tasks are `passed` or escalation is required:

### Step 1: Find ready tasks

```sql
SELECT * FROM spec_tasks WHERE status = 'ready';
```

If no tasks are ready and some are still `pending` or `blocked`, check whether a dependency cycle or persistent failure is blocking progress → escalate to user.

### Step 2: Implement in parallel

For each ready task, spawn an implementation subagent. The subagent receives:

- The task title, description, and **Definition of Done** from the spec
- The codebase context from Phase 1
- The "Decisions Already Made" and "Constraints" from the spec
- Any issues from previous attempts (read from `verification_log`)

**DoD as success criterion**: Pass the Definition of Done to the implementation subagent as the primary success criterion. The implementer knows their work is complete when the DoD is satisfied. Example instruction to subagent:

> "Implement Task 1: Implement user authentication. Your work is done when: **A user can log in with email/password and receive a JWT token that grants access to protected endpoints**. After implementation, the following checks will verify your work: [list deterministic checks and LLM-judge criteria]."

Update task status:
```sql
UPDATE spec_tasks SET status = 'implementing', attempt = attempt + 1, updated_at = datetime('now') WHERE id = ?;
```

Log the action:
```sql
INSERT INTO iteration_log (task_id, iteration, action, rationale) VALUES (?, ?, 'implement', ?);
```

### Step 3: Run deterministic checks

After implementation completes, run each deterministic check for the task:

- Execute the command specified in the check
- Evaluate whether the output matches the pass condition
- Log every result:

```sql
INSERT INTO verification_log (task_id, attempt, check_type, check_name, passed, evidence, issues)
VALUES (?, ?, 'deterministic', ?, ?, ?, ?);
```

**If any deterministic check fails:**
- If attempt < max_attempts → feed the failure evidence back to the implementer, set status = 'ready', and loop
- If attempt >= max_attempts → set status = 'blocked', escalate to user

**If all deterministic checks pass** → proceed to adversarial review.

### Step 4: Adversarial verification

Spawn a DIFFERENT model as the verifier. The verifier receives:

- The LLM-as-judge criteria from the task (stored in `llm_judge_criteria` field, or from aggregate table if not present)
- The **Definition of Done** for context: "This task is considered done when: [DoD]"
- The implementation output and any artifacts
- Instructions to evaluate objectively and produce a verdict per criterion

**Criteria format**: Parse the `llm_judge_criteria` JSON array for the task. Each criterion has:
- `name`: Identifier for the criterion
- `question`: The question the judge must answer
- `evidence`: What the judge should examine
- `scale`: The scoring rubric (typically 1-5 with descriptions)
- `pass_threshold`: Minimum score to pass (e.g., 4 means ≥ 4 passes)

**Fallback**: If `llm_judge_criteria` is empty, query the aggregate Evaluation Criteria > LLM-as-Judge Criteria table for entries matching this task.

The verifier must NOT be the same model that implemented. Use a different model ID or agent type.

Log every verdict:
```sql
INSERT INTO verification_log (task_id, attempt, check_type, check_name, passed, score, evidence, issues, verified_by)
VALUES (?, ?, 'llm_judge', ?, ?, ?, ?, ?, ?);
```

### Step 5: Evaluate convergence

After adversarial review, check whether the task passes:

```sql
SELECT check_name, passed, score FROM verification_log
WHERE task_id = ? AND attempt = ?;
```

**All criteria pass** (deterministic + LLM-judge above pass boundary):
```sql
UPDATE spec_tasks SET status = 'passed', updated_at = datetime('now') WHERE id = ?;
```

Then update newly ready tasks:
```sql
UPDATE spec_tasks SET status = 'ready'
WHERE status = 'pending'
AND NOT EXISTS (
  SELECT 1 FROM spec_tasks dep
  WHERE dep.id IN (SELECT value FROM json_each(spec_tasks.depends_on))
  AND dep.status != 'passed'
);
```

**Some criteria fail** — apply convergence rules:

1. Calculate improvement delta vs previous attempt:
```sql
SELECT AVG(score) FROM verification_log WHERE task_id = ? AND attempt = ?;
-- compare with attempt - 1
```

2. Check diminishing returns: if improvement < threshold from spec → escalate
3. Check max attempts: if attempt >= max_attempts → escalate
4. Otherwise: log the iteration, feed issues back, set status = 'ready', and loop

```sql
INSERT INTO iteration_log (task_id, iteration, action, rationale, improvement_delta)
VALUES (?, ?, 'verify', ?, ?);
```

---

## Phase 3: Escalation

When the autonomous loop cannot proceed, involve the user. Scenarios:

1. **Repeated deterministic failure** — present the failing check, evidence from all attempts, and ask: *"This check keeps failing. Should I try a different approach, adjust the spec, or skip this check?"*

2. **Convergence stall** — present the LLM-judge scores across iterations and ask: *"Quality isn't improving. The verifier says: [issues]. Should I try a different strategy, relax the criteria, or stop here?"*

3. **Wrong assumption** — if implementation reveals a spec assumption is incorrect, ask: *"The spec assumes X, but I found Y. Should I update the spec and continue, or pause for discussion?"*

4. **Dependency blocked** — if a task can't proceed because a dependency is stuck, explain the situation and ask for guidance.

After the user responds, update the relevant records and resume the loop.

---

## Phase 4: Completion

When all tasks in `spec_tasks` have status = 'passed':

1. **Update the spec** — set status to "Complete" and add a completion date
2. **Run a final integration check** — if the spec defines any cross-task checks, run them now
3. **Produce a summary** — query the DB for a completion report:

```sql
SELECT
  COUNT(*) as total_tasks,
  SUM(attempt) as total_attempts,
  (SELECT COUNT(*) FROM verification_log WHERE passed = 1) as checks_passed,
  (SELECT COUNT(*) FROM verification_log WHERE passed = 0) as checks_failed
FROM spec_tasks;
```

4. **Report to user** — present: tasks completed, total iterations, any spec updates made, and overall pass rate

---

## Principles

- **The DB drives decisions** — never rely on conversation memory for progress state. Always query.
- **DoD is the success criterion** — every task has a Definition of Done. Pass it to implementers and verifiers as the primary completion signal. "Done when" is not metadata — it's the contract.
- **Inline evaluation first, aggregate fallback** — prioritize inline evaluation criteria from each task. Fall back to aggregate tables only when inline is missing (backward compatibility).
- **Fail fast on deterministic checks** — they're cheap. Run them before expensive adversarial review.
- **Adversarial is non-negotiable** — the verifier is always a different model. This is the quality guarantee.
- **Parallel where possible** — independent tasks should never wait for each other.
- **Escalate early** — don't burn through all max_attempts on an approach that clearly won't work. If the second attempt shows no improvement, consider escalating.
- **Update the spec** — if implementation reveals new information, update `./specs/<name>.md` to keep it accurate. The spec is a living document.

---

## Status reporting

At any point, the user can ask "what's the status?" and the skill should query:

```sql
SELECT status, COUNT(*) as count FROM spec_tasks GROUP BY status;
```

And show a progress summary. The DB is always the source of truth.
