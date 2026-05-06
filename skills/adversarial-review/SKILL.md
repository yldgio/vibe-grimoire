---
name: adversarial-review
description: >-
  Launch a bounded adversarial review panel for code, PRs, designs, PRDs, or
  docs. The first pass establishes the review contract: baseline, scope,
  blocker policy, desired end state, and a state file for medium/complex
  reviews. Later passes verify whether the agreed blockers were cleared instead
  of reopening the whole problem space. Reviewers stay explicitly adversarial —
  challenging assumptions, surfacing failure modes, and questioning design
  choices without bias toward the existing work. Use when the user asks for a
  critical review, design critique, architecture review, or red-team style
  feedback such as "tear this apart", "what could go wrong?", or "review this
  PR".
---

# Adversarial Review

Orchestrate an adversarial review panel — each reviewer assigned a distinct attack vector. On the first pass, the panel maps the risk landscape and defines the blocker set. On later passes, it verifies whether the work has reached the agreed desired state without reopening the entire universe.

The goal is **not** to prove that no issue exists. The goal is to close the in-scope blocker set, record accepted or deferred risks explicitly, and produce a clear proceed / don't proceed decision.

**Skill workflow:**
[`pre-mortem`](#) *(stress-test before building)* → **`adversarial-review`** *(tear apart what was built)* → [`adr`](#) *(record decisions that emerged from the review)*

---

## Scope

This skill handles: complexity assessment, subject discovery, review contract setup, state file creation/reuse, adversarial reviewer orchestration, parallel review execution with distinct attack vectors, finding synthesis, convergence detection, and closure decisions.

This skill does **not** apply fixes. Its job is to find problems, classify them, and decide whether the agreed blocker set is closed. For remediation, use the appropriate skill: `refactoring` for structural fixes, `design-patterns` for design-level recommendations, `tdd` for testability issues, `clean-code` for code quality.

This skill also does **not** reset the goalposts on every pass. New observations that fall outside the agreed review contract become follow-up items unless they are new in-scope `Critical` / `High` regressions introduced by the remediation.

For `Medium` and `Complex` reviews, create or reuse a state file such as `./reviews/<slug>-review-state.md`. Use [`references/review-state-template.md`](references/review-state-template.md) as the starting template.

---

## Step 1: Assess complexity

Before launching reviewers, assess what is being reviewed. Size up the blast radius of a mistake — how bad would it be if there is a subtle flaw here?

**🟢 Simple** — A small, isolated change: a single-function fix, a one-line config change, a trivial renaming, a minor doc correction.
→ **Push back gently.** Tell the user: *"This looks pretty straightforward — a full adversarial panel might be more than you need here. Want me to proceed anyway, or would a quick inline review do the job?"* Wait for their answer before continuing.

**🟡 Medium** — A self-contained feature: a new endpoint, a module-level refactor, a small architectural decision, a PR with 3–10 file changes, a design doc scoped to one component.
→ Launch **1–2 reviewers**. Default to 1 if the scope is truly narrow and well-contained. Escalate to 2 if there are non-trivial architectural dimensions or the failure mode of getting this wrong is costly. Create or reuse a review state file by default.

**🔴 Complex** — A system design, a cross-cutting refactor, a new service, a large PR (10+ files), an architectural choice with broad organizational impact, a PRD for a significant feature, or anything touching multiple teams or systems.
→ Launch **3 reviewers** by default. Launch more only if the user explicitly asks for it. Create or reuse a review state file by default.

When in doubt on **Medium** or **Complex** work, lean toward more reviewers. The cost of an extra review pass is low; the cost of a missed critical issue is not. The cost of an *unbounded* review loop is also real, so define the review contract before you let the panel loose.

---

## Step 2: Identify what to review

Before spawning any reviewer, understand the subject. If the user hasn't pointed to a specific artifact, ask: *"What should I review — a file or set of files, a PR diff, a design doc, or a description you'll paste in?"*

- **Code / PR**: Explore the diff and changed files. Understand the intent before judging the approach.
- **Architecture / Design**: Read the design doc, ADR, or description. Identify the key decisions and the assumptions baked into them.
- **Documentation**: Read the document. Understand what it claims to be true and what it is trying to convey.
- **PRD / Plan**: Read the requirements. Identify what is being committed to and what is left ambiguous.

If the same subject was reviewed previously, look for the existing state file first. A verification pass without the previous state is just a brand-new teardown wearing a fake mustache.

---

## Step 3: Establish the review contract

Before launching reviewers, write down the review contract explicitly. The contract defines both the **baseline** and the **desired end state** so the review has a destination instead of turning into endless critique.

Capture the following:

- **Subject** — what is being reviewed
- **Artifacts** — files, PR diff, design sections, or pasted content
- **Review mode** — `Baseline` or `Verification`
- **Baseline state** — what is true right now
- **Desired end state** — what must be true for this review to stop
- **In scope** — what the panel is allowed to block on
- **Out of scope** — what may be noted but must not reset closure
- **Blocker policy** — what counts as a must-fix-now issue
- **Accepted risks** — risks the user or team already accepts
- **Review budget** — default to `Baseline` + one `Verification` pass for `Medium` / `Complex` reviews unless the user asks for more or the scope changes materially
- **State file path** — usually `./reviews/<slug>-review-state.md`

Default blocker policy:

- `Critical` / `High` findings in scope are blockers until marked `Resolved`, `Accepted Risk`, `Out of Scope`, or `False Positive`
- `Medium` / `Low` findings are advisory by default and may be marked `Deferred` or `Accepted Risk`
- New out-of-scope findings do **not** block closure
- New `Critical` / `High` regressions introduced by remediation **do** block closure

Default desired end state:

- The agreed target verdict is explicit up front: usually `CONDITIONAL` or `PROCEED WITH CAUTION`
- No unresolved in-scope `Critical` / `High` blockers remain
- Remaining `Medium` / `Low` findings have a recorded disposition

For `Medium` and `Complex` reviews, create or update the state file now. Reuse stable finding IDs such as `AR-001`, `AR-002`, and so on. Never renumber them between passes.

---

## Step 4: Assign adversarial roles

Each reviewer gets a distinct attack vector. Role diversity ensures coverage diversity — the panel finds different categories of problems rather than multiple reviewers converging on the same visible surface issue.

| Reviewer | Preferred model | Attack Vector |
|----------|-----------------|---------------|
| 🔴 **The Skeptic** | `gpt-5.4` | Challenges fundamental design choices: *"Why this approach at all? What did we not consider? What problem does this actually solve, and is that the right problem?"* Targets wrong-level abstractions, missing requirements, and hidden assumptions baked into the design. |
| ⚡ **The Executioner** | `claude-sonnet-4.6` | Hunts for failure modes: *"What breaks, when, and how badly?"* Targets correctness, edge cases, error handling, race conditions, security vulnerabilities, and silent data corruption. |
| 🔨 **The Pragmatist** | `gpt-5.3-codex` | Attacks production viability: *"Will this survive real-world load, real-world teams, and real-world time?"* Targets maintainability, operability, testability, performance under stress, and the hidden long-term costs of the implementation choices. |

If a preferred model is unavailable, keep the role and attack vector the same and use the closest available substitute. The role matters more than the exact model label.

When using fewer than 3 reviewers:
- **1 reviewer**: Default to The Executioner (`claude-sonnet-4.6`) — correctness and failure modes are the highest-value adversarial lens for most contexts. This is a single-lens review, not a full panel.
- **2 reviewers**: Add The Skeptic (`gpt-5.4`) — design questioning pairs well with failure-mode hunting and surfaces a different class of issue.

---

## Step 5: Launch reviewers in parallel

If there is more than one reviewer, spawn them simultaneously — do not wait for one to finish before starting the next. If there is only one reviewer, run that review directly.

Use this subagent prompt template for each reviewer:

```text
You are [ROLE NAME], an adversarial reviewer.

Your attack vector: [ATTACK VECTOR — copy from the table above]

Your posture: You are NOT here to validate this work. You are here to find everything wrong with it that matters for the current review contract. Challenge the approach. Surface the failure modes. Question the assumptions. Do not soften your findings — if something is fragile, dangerous, or misguided, say so clearly and explain why.

Review contract:
- Mode: [Baseline | Verification]
- Desired verdict: [DO NOT MERGE | CONDITIONAL | PROCEED WITH CAUTION]
- In scope: [IN-SCOPE ITEMS]
- Out of scope: [OUT-OF-SCOPE ITEMS]
- Blocker policy: [BLOCKER POLICY]
- Accepted risks: [ACCEPTED RISKS]
- State file: [PATH OR "inline only"]
- Open blocker IDs: [LIST OR "none yet"]

Subject under review:
[ARTIFACT: file paths, diff, design description, or pasted content]

Review instructions:
- If mode is `Baseline`: find the most important in-scope issues and classify whether each is `Blocker Now`, `Follow-up`, `Accepted Risk Candidate`, `Out of Scope`, or `False Positive Candidate`. Prioritize issues that materially affect the desired verdict. Do not optimize for volume.
- If mode is `Verification`: focus on whether the open blocker IDs are actually resolved and whether the remediation introduced new in-scope `Critical` / `High` regressions in the touched areas. Do NOT reopen settled or out-of-scope areas just to find novelty.
- If you notice a new `Medium` / `Low` issue or an out-of-scope issue during `Verification`, record it as `Follow-up` instead of using it to block closure unless it proves the desired end state is still impossible.

For each finding, provide:
- Finding ID: [existing ID if verifying, otherwise `NEW`]
- Severity: Critical / High / Medium / Low
- Disposition: Blocker Now | Follow-up | Accepted Risk Candidate | Out of Scope | False Positive Candidate
- Category: Correctness | Design | Security | Performance | Maintainability | Observability | Other
- Issue: What is wrong, stated precisely
- Why it matters: The consequence of leaving this unaddressed
- Evidence: Where specifically in the artifact this appears (line number, section, quote)
```

If the user provided context (intent, constraints, prior decisions), include it in the subagent prompt — adversarial reviewers should challenge whether the constraints are right, not ignore them.

---

## Step 6: Synthesize findings and update state

Once the review completes, produce a unified adversarial review report and update the state file if one exists.

```text
# Adversarial Review — [Subject]
_Reviewed by: [list active reviewers]_

## Review Contract
- Mode: [Baseline | Verification]
- Desired verdict: [TARGET VERDICT]
- In scope: [SUMMARY]
- Out of scope: [SUMMARY]
- Blocker policy: [SUMMARY]
- Review budget / pass count: [SUMMARY]
- State file: [PATH OR "inline only"]

## Baseline vs Desired State
[What is true now, what must be true to stop, and the current gap]

## ⚠️ Blockers to Clear Now
[Open in-scope `Critical` / `High` issues or convergent `High` issues that still prevent the desired verdict]

## 🟡 Deferred / Accepted Risks
[Issues intentionally deferred, accepted, marked out of scope, or determined to be false positives]

## 🔎 Follow-up Findings
[Non-blocking `Medium` / `Low` issues, plus anything out of scope that should be tracked elsewhere]

## 🔗 Convergence
[Include only when 2 or more reviewers were used. Issues independently surfaced by 2 or more reviewers.
These deserve the most attention — independent adversarial reviewers reaching the same conclusion is a strong signal.]

## ⚡ Dissents
[Include only when reviewers disagreed or contradicted each other. Surface the tension.
Do not flatten genuine conflicts into silence — the disagreement itself is informative.]

## Closure Decision
- Target state reached: Yes / No
- Remaining blocker IDs: [LIST OR "none"]
- Next action: [Stop | Remediate blockers | Narrow / restate contract]

## Verdict
🔴 DO NOT MERGE / DO NOT PROCEED — critical issues must be resolved first.
🟡 CONDITIONAL — specific blockers must be addressed before this goes further.
🟢 PROCEED WITH CAUTION — no blockers remain, but follow-up items and accepted risks should inform the next steps.
```

State-file rules:

- Assign stable IDs to new findings on the first pass
- On later passes, update the status of existing IDs instead of inventing replacements
- Valid statuses are: `Open`, `Resolved`, `Accepted Risk`, `Deferred`, `Out of Scope`, `False Positive`
- New `Medium` / `Low` or out-of-scope observations found during `Verification` go to follow-up unless they are evidence of a new in-scope blocker
- If the scope changed materially, stop and restate the review contract before launching another full pass

**Why convergence is the most important section when present:** When two or three reviewers with different models and different attack vectors independently surface the same issue, that finding is not a coincidence — it is a near-certainty. These are the issues most likely to cause real damage if ignored.

**Why dissents are preserved when present:** An adversarial reviewer flagging something that another dismisses is not noise — it is a tension worth the user's attention. Collapsing genuine conflicts into a majority verdict defeats the purpose of using multiple reviewers.

---

## Step 7: Stop when the contract is satisfied

End the review when **either** of these is true:

1. **Target state reached**
   - No unresolved in-scope `Critical` / `High` blockers remain
   - Each prior blocker is now `Resolved`, `Accepted Risk`, `Out of Scope`, or `False Positive`
   - Remaining `Medium` / `Low` findings have an explicit disposition
   - The target verdict has been reached

2. **Review budget exhausted**
   - The planned passes are complete
   - Open blocker IDs are listed clearly
   - The remaining gap is returned to the user without launching a fresh unrestricted panel

Adversarial review is **not** a hunt for zero findings. A review can conclude with deferred items, follow-up work, and accepted risks. The key question is whether the agreed blocker set is closed — not whether a clever reviewer can invent one more thing to worry about.

When done, return control to the user with the closure decision, the remaining gap list if any, and the state file path if one was used.
