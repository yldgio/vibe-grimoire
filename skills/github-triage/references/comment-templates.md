# Comment Templates

Comment bodies to post per category. Write the chosen body to a temp markdown file
and pass it with `gh ... --body-file <file>` to avoid shell-quoting problems.

## `needs-info` — triage notes

Post when the claim cannot be evaluated without more from the reporter. Leave the
item open.

```markdown
## Triage Notes

**What we've established so far:**

- point 1
- point 2

**What we still need from you (@reporter):**

- question 1
- question 2
```

## `ready-for-agent` — agent brief

Post the agent brief. Use the full spec, principles, and examples in
[agent-briefs.md](./agent-briefs.md). The brief is the contract the AFK agent works
from, so it must have a category, current vs desired behavior, key interfaces,
testable acceptance criteria, and explicit scope boundaries.

## `ready-for-human` — brief + delegation blocker

Same structure as an agent brief, plus a note stating **why it cannot be delegated
to an AFK agent**. Pick the reasons that apply: judgment calls, external access
(credentials, third-party systems, hardware), design decisions, or manual testing.

```markdown
## Agent Brief (human)

**Category:** bug / enhancement
**Summary:** one-line description of what needs to happen

**Current behavior:**
...

**Desired behavior:**
...

**Key interfaces:**
- ...

**Acceptance criteria:**
- [ ] ...
- [ ] ...

**Out of scope:**
- ...

**Why this needs a human:**
- e.g. requires a design decision on <X> with no single correct answer
- e.g. requires access to <external system / credentials / hardware>
- e.g. requires manual testing on <device / environment> that an agent cannot reach
```

## `wontfix` — close comments

Add the `wontfix` label, post the matching comment, then close
(`gh issue close <n> --reason "not planned" --body-file wontfix.md`). The comment
depends on **why**.

### Already implemented

The change already exists in the codebase. Point to where it lives (by concept or
symbol, not a stale path) so the reporter can find it.

```markdown
## Already Implemented

This already exists in the codebase — see `<type / function / command>`, which
provides `<behavior>`.

If it isn't behaving as you expect, please open a new issue with steps to
reproduce and we'll treat it as a bug. Closing as already implemented.
```

### Rejected — bug

The reported behavior is working as intended, or is out of the project's control.
Explain politely, then close.

```markdown
## Working as Intended

Thanks for the report. This behavior is intentional because `<reason>` / is caused
by `<external factor outside this project>`.

<Optional: the supported way to achieve the reporter's underlying goal.>

Closing, but happy to revisit if there's a concrete case this breaks.
```

### Rejected — enhancement

The request is out of scope for the project. Explain politely as out of scope, then
close.

```markdown
## Out of Scope

Thanks for the suggestion. This is out of scope for the project because `<reason —
misaligned with goals / maintenance cost / better solved elsewhere>`.

Closing as out of scope. If the underlying need is common, a focused proposal that
addresses `<constraint>` is welcome as a new issue.
```
