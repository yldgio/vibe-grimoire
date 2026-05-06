# Review State Template

Use this template for `Medium` and `Complex` adversarial reviews. Create the runtime file at `./reviews/<slug>-review-state.md` on the `Baseline` pass, then reuse the same file on each `Verification` pass.

This file is the single source of truth for:
- the review contract,
- the blocker set,
- stable finding IDs,
- accepted risks,
- follow-up items,
- and the current closure decision.

If the subject changes materially, do **not** keep extending the same state file blindly. Restate the review contract or create a new state file.

## Status values

| Status | Meaning |
|---|---|
| `Open` | Still blocks the desired end state |
| `Resolved` | Verified as fixed or no longer present |
| `Accepted Risk` | Intentionally tolerated and documented |
| `Deferred` | Real issue, but not required for current closure |
| `Out of Scope` | Not part of the agreed blocker set |
| `False Positive` | Reviewer concern did not hold up under verification |

## Disposition guidance

- Use `Blocker Now` for in-scope `Critical` / `High` issues that prevent the target verdict.
- Use `Follow-up` for non-blocking issues that should be tracked after closure.
- Use `Accepted Risk Candidate` when the issue is real but may be consciously tolerated.
- Use `Out of Scope` when the observation is valid but outside the agreed contract.
- Use `False Positive Candidate` when the concern likely does not survive closer inspection.

## Template

```markdown
# Adversarial Review State — [Subject]

## Contract
- Subject: [What is being reviewed]
- Artifacts: [Files, PR diff, design sections, or pasted content]
- Review mode: [Baseline | Verification]
- Baseline state: [What is true right now]
- Desired verdict: [DO NOT MERGE | CONDITIONAL | PROCEED WITH CAUTION]
- Desired end state: [What must be true to stop]
- In scope: [What the panel may block on]
- Out of scope: [What may be noted but must not reset closure]
- Blocker policy: [How issues become blockers]
- Accepted risks: [Known risks already tolerated]
- Review budget: [Usually Baseline + one Verification pass]
- State file: ./reviews/[slug]-review-state.md
- Last updated: [YYYY-MM-DD]

## Current Closure Status
- Target state reached: [Yes | No]
- Remaining blocker IDs: [AR-001, AR-004, ... | none]
- Next action: [Stop | Remediate blockers | Narrow / restate contract]
- Current verdict: [DO NOT MERGE | CONDITIONAL | PROCEED WITH CAUTION]

## Findings Ledger
| ID | Status | Severity | Category | Disposition | Summary | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| AR-001 | Open | High | Correctness | Blocker Now | [Short summary] | [File / section / quote] | [Why it matters, latest update] |
| AR-002 | Deferred | Medium | Maintainability | Follow-up | [Short summary] | [File / section / quote] | [Tracked after closure] |

## Pass History

### Pass 1 — Baseline
- Date:
- Reviewers:
- Summary:
- New IDs assigned:
- Convergence:
- Dissents:
- Verdict:

### Pass 2 — Verification
- Date:
- Reviewers:
- Blockers checked:
- Status changes:
- New regressions found:
- Verdict:

## Accepted Risks / Deferred Follow-up
- [Risk or follow-up item]
- [Owner, if known]
- [Where it should be tracked next]
```

## Usage rules

1. Assign stable IDs on the first pass and reuse them forever.
2. Update status instead of replacing rows when a blocker changes state.
3. During `Verification`, new `Medium` / `Low` findings normally go to follow-up rather than reopening closure.
4. Only new in-scope `Critical` / `High` regressions introduced by remediation should reset the blocker set.
5. A review can close with `Deferred`, `Accepted Risk`, and follow-up items present. Closure means the agreed blocker set is closed — not that every possible concern has vanished.
