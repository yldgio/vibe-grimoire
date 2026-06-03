---
name: playbook-design
description: >-
  Interview the developer about their workflow goals and produce a valid
  Playbook YAML file saved to ./playbooks/<name>.yml. A Playbook is a
  machine-executable workflow graph: Phases (logical groupings) containing
  Tasks (atomic executable units with inputs, outputs, dependencies, and
  success criteria). Trigger this skill when the user wants to design,
  create, edit, or author a repeatable multi-step agentic workflow. Covers the
  full interview → validate → save flow, including updating existing playbooks.
---

# playbook-design

Guide the developer through a structured interview to design a **Playbook** — a repeatable, versioned, executable workflow. Produce a valid YAML artifact and save it to `./playbooks/<name>.yml` in their repo.

---

## Process

### Step 1: Establish the goal

Ask the developer:
- What workflow are you trying to automate or standardise?
- What triggers it, and what does a successful run look like?
- Roughly how many steps does it have? Are any steps parallel or conditional?

Confirm understanding before continuing.

### Step 2: Name and describe the playbook

Collect:
- **`name`** — kebab-case slug (e.g. `implement-from-issue`, `release-pipeline`). This becomes the filename.
- **`description`** — one sentence describing what the playbook does.
- **`version`** — default `"1.0"` unless the developer specifies otherwise.

### Step 2.5: Elicit variables

Ask: *"Does this workflow need runtime inputs that vary each time you run it? For example, an issue URL, branch name, or target environment."*

If yes, collect for each variable:
- **`name`** — a short identifier in snake_case (preferred) or kebab-case (e.g. `issue_url`, `branch_name`, `target_env`). Prefer snake_case to avoid ambiguity in `{{ variables.<name> }}` substitution.
- **`default`** — a default value (string). Leave empty `""` if the variable is **required** at runtime; provide a non-empty string for an optional variable with a fallback.

Variables are referenced in task `prompt` and `input` fields as `{{ variables.<name> }}`. `playbook-execute` will collect required variables from the developer before starting execution.

If no variables are needed, skip this step.

---

### Step 3: Elicit phases

Ask the developer to name the logical groupings of their workflow (e.g. *understand*, *implement*, *verify*). For each phase collect:
- **`name`** — kebab-case
- **`description`** — one sentence

Phases are ordering hints for human readers; execution order is driven by task `depends_on`.

### Step 4: Elicit tasks

For each task, interview the developer to collect all schema fields. Go phase by phase. For each task:

| Field | Question to ask |
|-------|----------------|
| `name` | What is a short, unique slug for this task? (kebab-case) |
| `phase` | Which phase does this task belong to? |
| `capability` | What type of work does this task do? (`research` / `implementation` / `verification` / `review` / `decision`) |
| `executor` | Which agent should run this? (`main` / `explore` / `code-review` / `security-review` / `human` / `custom:<name>`) — optional, leave blank if you want capability-based fallback |
| `depends_on` | Which earlier tasks must complete before this one starts? (list of task name slugs) |
| `input` | What artefacts or values does this task receive? Can be a single filename (string), list of filenames, or mapping of named inputs (key: value pairs). |
| `output` | What artefact or state does this task produce? |
| `prompt` | What should the executor do? (instructions for the agent or human) |
| `success` | What observable result confirms this task is done? Be concrete — file exists, test passes, developer responded, etc. |
| `on_failure` | What happens if this task fails? (`stop` / `skip` / `retry` / `fallback:<task-name>`) — default `stop` |

**Tip:** For decision or approval gates, use `executor: human`. The developer will be shown `prompt` and asked to respond.

**After collecting `success`:**

**Quality check** — if the developer's answer contains only vague wording (e.g., "done", "complete", "finished", "task is done") with no specific file, output, or command, warn:

> *"This success criterion may be hard to verify automatically. Can you be more specific? For example: the name of a file produced, a command that should pass, or a visible outcome."*

Ask the developer to revise before continuing.

**Offer structured `checks`** — once `success` is non-vague, ask:

> *"Would you like to add structured `checks` for this task? These allow `playbook-execute` to verify completion automatically using tools."*

If yes, walk through checks by category:
- *"Does this task produce a file?"* → offer `file_exists` and/or `file_contains` check
- *"Can success be confirmed by running a command?"* → offer `command` check
- *"Does this require your manual confirmation?"* → offer `human` check
- *"Can success only be evaluated holistically — e.g., no critical findings remain, or the output reads correctly?"* → offer `agent_confirms` check

Collect only the checks the developer confirms. Include the `checks` field in the output YAML.
If no: record only `success` — `playbook-execute` will use its judgment protocol at runtime.

### Step 5: Validate before saving

Apply these rules and raise any violations before writing the file:

1. **Unique slugs**: every task `name` must be unique within the playbook.
2. **Kebab-case names**: task `name` and phase `name` values must match `[a-z][a-z0-9-]*`.
3. **Phase reference**: every task's `phase` must match a phase `name` declared in the `phases` list.
4. **depends_on integrity**: every slug in a `depends_on` list must reference a task that exists in the playbook.
5. **No cycles**: the dependency graph must be acyclic (topologically sortable).
6. **success is mandatory**: every task must have a non-empty `success` field.
7. **capability is mandatory**: every task must have a valid `capability` value — one of `research | implementation | verification | review | decision`.
8. **executor value**: if `executor` is specified, it must be one of `main | explore | code-review | security-review | human | custom:<name>`.
9. **on_failure value**: must be one of `stop | skip | retry | fallback:<task-name>`.
10. **fallback target exists**: if `on_failure: fallback:<task-name>`, that task name must exist in the playbook and must not equal the current task's name.

If any rule is violated, point it out to the developer, ask for the correction, and re-validate.

### Step 6: Preview and confirm

Show the developer the full YAML. Ask: *"Does this look right? Any changes before I save?"*

Apply any corrections, re-validate, then save.

### Step 7: Check for existing playbook

Before saving, check if a playbook with the same `name` already exists at `./playbooks/<name>.yml`. If it does:
- Show the developer the existing file.
- Ask: *"This playbook already exists. Do you want to edit it incrementally, or create a new version?"*
- If **edit**: load the existing YAML, merge the developer's changes incrementally, re-validate, then save.
- If **new version**: increment the `version` field (e.g., `"1.0"` → `"2.0"`), save with the updated name if needed, or save as a separate artifact.

### Step 8: Save

Save the playbook to `./playbooks/<name>.yml` (where `<name>` is the playbook's `name` field).

Confirm to the developer: *"Saved to `./playbooks/<name>.yml`. Run it with the `playbook-execute` skill."*

---

## Playbook YAML Schema

```yaml
name: <slug>                   # kebab-case, becomes the filename
description: <string>          # one-sentence summary
version: "1.0"                 # semver string

variables:                     # optional — runtime inputs; referenced as {{ variables.<name> }}
  <var-name>: ""               # empty string = required at runtime; non-empty = default

phases:                        # optional but recommended — provides structure and context
  - name: <slug>
    description: <string>

tasks:
  - name: <slug>               # kebab-case, unique within playbook
    phase: <phase-name>        # must match a phase name above
    capability: <value>        # research | implementation | verification | review | decision
    executor: <value>          # optional: main | explore | code-review | security-review | human | custom:<name>
    depends_on:                # optional list of task name slugs
      - <task-name>
    input:                     # optional — artefacts or variables received
                               # Can be: string (single artifact), list (multiple artifacts), or mapping (key-value pairs)
      <key>: <value>           # Use mapping for named references; use string/list for ordered artifact references
    output: <string>           # optional — artefact or state produced (name or description of output)
    prompt: |                  # executor instructions
      <text>
    success: |                 # mandatory — observable completion criteria
      <text>
    checks:                    # optional — typed verification steps (all must pass); backward compatible
      - type: file_exists      # file must exist and be non-empty
        path: <path>
      - type: file_contains    # file must contain pattern (substring match)
        path: <path>
        pattern: <substring>
      - type: command          # run shell command; check exit code
        run: <shell command>
        expect_exit: 0         # default 0
        expect_output: <str>   # optional: stdout must contain this string
      - type: human            # pause and ask developer YES/NO
        prompt: <question>
      - type: agent_confirms   # agent evaluates with LLM judgment
        description: <text>
    on_failure: stop           # stop | skip | retry | fallback:<task-name>
```

---

## Concrete Example

The following is a complete, valid Playbook demonstrating the current schema features. Use it as a reference when writing or editing playbooks manually.

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
    checks:
      - type: file_exists
        path: issue-summary.md
      - type: file_contains
        path: issue-summary.md
        pattern: "acceptance criteria"
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
    prompt: |
      Read issue-summary.md and codebase-analysis.md.
      Implement the feature described. Follow existing patterns from codebase-analysis.md.
      Ensure all acceptance criteria from issue-summary.md are addressed.
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
    checks:
      - type: file_exists
        path: security-findings.md
      - type: agent_confirms
        description: No CRITICAL or HIGH severity findings remain unresolved in security-findings.md
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

## Notes

- Playbooks live in the **user's repo** under `./playbooks/` — they are versioned alongside the code they automate.
- `{{ variables.<name> }}` tokens in `prompt` and `input` are substituted at runtime by `playbook-execute` — they are recorded as-is in the YAML and resolved during execution.
- `!include <path>` in a `prompt` field tells `playbook-execute` to load the referenced Markdown file at runtime and use its content as the prompt. The path must be relative to the playbook file. Useful for long, rich prompts that would clutter the YAML.
- Tasks that have no blocking `depends_on` relationship run in parallel during execution. If the developer wants two tasks to run in parallel, simply do not add a `depends_on` between them.
- A playbook with no `depends_on` anywhere is valid: all tasks are ready immediately and launch simultaneously in one parallel batch.
- The `executor` field is optional. When omitted, `playbook-execute` selects an executor based on `capability`.

When the playbook is saved, return control to the user.
