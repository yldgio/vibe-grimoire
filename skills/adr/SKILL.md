---
name: adr
description: Create an Architectural Decision Record (ADR) to formally document a significant technical or architectural choice. Use whenever a user says "write an ADR", "document this decision", "record why we chose X", "capture this architecture choice", "explain why we went with Y", "document the trade-offs", "write up this tech decision", or makes any significant architectural choice that future teammates will need to understand. Also use proactively when you observe a meaningful decision being made during a session — even if the user hasn't explicitly asked for an ADR. ADRs prevent teams from re-debating settled choices and preserve context that would otherwise become tribal knowledge lost to future maintainers.
---

# Create an Architectural Decision Record

An ADR is a short, durable document that captures a significant technical choice: what was decided, why, what was rejected, and what consequences to expect. Its primary audience is future engineers — months or years later — who need to understand *why* the codebase is shaped the way it is, not just *how* it works. Writing an ADR also forces you to surface hidden assumptions and trade-offs at the moment they are freshest.

## Process

### 1. Extract context from the conversation

Read the conversation carefully before asking anything. Identify:

- The decision being made (or recently made)
- The problem or constraint that forced it
- Alternatives that were considered or dismissed
- The author (`git config user.name` / `git config user.email` if available, otherwise ask)

If a critical piece is still missing after reading the context, ask one focused question. Asking multiple questions at once creates friction and often isn't necessary — you can make reasonable inferences and note them in the draft.

### 2. Check for existing ADRs

Look for an existing ADR directory — common locations are `docs/adr/`, `doc/adr/`, `docs/decisions/`, or `architecture/decisions/`.

- List existing ADRs to determine the next sequential number
- Scan titles for related decisions that should be referenced or marked as superseded
- Note any naming conventions already in use

If no directory exists, create `docs/adr/`.

### 3. Draft and confirm

Show the ADR draft inline in the conversation before saving. A quick confirmation prevents wasted round-trips. If the user approves, save; if they want changes, apply them first.

### 4. Save the file

Save to:

```
docs/adr/adr-NNNN-[title-slug].md
```

- `NNNN`: 4-digit zero-padded number, next in sequence (e.g., if `adr-0003` exists, use `0004`)
- `title-slug`: title in kebab-case, lowercase, hyphens only (e.g., `use-postgresql`)

After saving, print the file path and a one-line summary of the decision.

## Writing guidelines

Good ADRs age well. These guidelines help:

- **Context describes the problem, not the solution.** Explain the forces, constraints, and situation that made a decision necessary. What would happen if you did nothing?
- **Decision is the chosen option, stated plainly**, with the key reason it beat the alternatives.
- **Consequences must be honest.** List real trade-offs, not just upsides. An ADR with only positive consequences is incomplete — every real choice costs something.
- **Alternatives explain *why they were rejected*, not just what they are.** This is the most valuable part for future readers. "We considered Redis but chose Postgres because..." is infinitely more useful than just listing Redis as an option.
- **Write at the module/behavior level.** Avoid file paths and line numbers — they rot quickly. The ADR should still make sense after a major refactor.
- **Use the project's domain language.** Avoid filler phrases like "robust", "scalable", or "flexible" without concrete, measurable meaning.

## ADR Template

Include only sections with content. `Alternatives Considered`, `Implementation Notes`, and `References` are optional — omit them if they don't apply.

```markdown
---
title: "ADR-NNNN: [Decision Title]"
status: "Proposed"
date: "YYYY-MM-DD"
authors: "[Author Name(s)]"
tags: ["architecture", "decision"]
supersedes: ""
superseded_by: ""
---

# ADR-NNNN: [Decision Title]

## Status

**Proposed** | Accepted | Rejected | Superseded | Deprecated

## Context

[The problem, constraints, and forces that required a decision. What changed or became necessary? What is the cost of doing nothing?]

## Decision

[The chosen solution, stated plainly. Why this over the alternatives?]

## Consequences

### Positive

- [Beneficial outcome or advantage]
- [Performance, maintainability, or scalability improvement]

### Negative

- [Trade-off, limitation, or drawback]
- [Technical debt or complexity introduced]
- [Risk or future challenge to monitor]

## Alternatives Considered *(optional)*

### [Alternative Name]

**Description**: [Brief description of the approach]

**Why rejected**: [Specific reason this was not chosen]

## Implementation Notes *(optional)*

- [Key implementation consideration]
- [Migration or rollout strategy, if non-trivial]
- [Monitoring or success criteria, if measurable]

## References *(optional)*

- [Related ADRs — link by number, e.g., "See ADR-0002"]
- [External documentation, RFCs, or standards]
```

## Status lifecycle

| Status | Meaning |
|--------|---------|
| **Proposed** | Under discussion — not yet in effect |
| **Accepted** | Approved and being implemented or in use |
| **Rejected** | Considered but not adopted |
| **Superseded** | Replaced by a newer ADR — set `superseded_by` with the new ADR number, and update the new ADR's `supersedes` field |
| **Deprecated** | No longer relevant but preserved for historical context |

Start with **Proposed** unless the decision is already implemented, in which case use **Accepted**. Updating status is a separate commit from creating the ADR — it signals team review happened.