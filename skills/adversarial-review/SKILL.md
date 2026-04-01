---
name: adversarial-review
description: >-
  Launch a multi-model adversarial review panel to stress-test code,
  architectural designs, PRDs, pull requests, or documentation. Each reviewer
  runs with a different AI model and an explicitly adversarial posture —
  challenging assumptions, surfacing failure modes, and questioning design
  choices without bias toward the existing work. Use this skill whenever the
  user asks for a code review, design critique, PR review, architecture review,
  or any adversarial or critical feedback. Trigger on: "tear this apart", "what
  could go wrong?", "challenge this", "adversarial review", "red team this",
  "find the holes in", "review this PR", "critique this design", "stress-test
  this", or any review where finding problems matters more than confirming what
  works. Scale is automatic: simple tasks get a gentle pushback, medium
  complexity gets 1–2 reviewers, complex tasks get 3 reviewers by default.
---

# Adversarial Review

Orchestrate a multi-model panel of adversarial reviewers — each powered by a different AI model, each assigned a distinct attack vector. The goal is not balanced feedback: it is to surface every weakness, assumption gap, edge case, and failure mode before they reach production.

**Skill workflow:**
[`pre-mortem`](#) *(stress-test before building)* → **`adversarial-review`** *(tear apart what was built)* → [`adr`](#) *(record decisions that emerged from the review)*

---

## Step 1: Assess complexity

Before launching reviewers, assess what is being reviewed. Size up the blast radius of a mistake — how bad would it be if there is a subtle flaw here?

**🟢 Simple** — A small, isolated change: a single-function fix, a one-line config change, a trivial renaming, a minor doc correction.
→ **Push back gently.** Tell the user: *"This looks pretty straightforward — a full adversarial panel might be more than you need here. Want me to proceed anyway, or would a quick inline review do the job?"* Wait for their answer before continuing.

**🟡 Medium** — A self-contained feature: a new endpoint, a module-level refactor, a small architectural decision, a PR with 3–10 file changes, a design doc scoped to one component.
→ Launch **1–2 reviewers**. Default to 1 if the scope is truly narrow and well-contained. Escalate to 2 if there are non-trivial architectural dimensions or the failure mode of getting this wrong is costly.

**🔴 Complex** — A system design, a cross-cutting refactor, a new service, a large PR (10+ files), an architectural choice with broad organizational impact, a PRD for a significant feature, or anything touching multiple teams or systems.
→ Launch **3 reviewers** by default. Launch more only if the user explicitly asks for it.

When in doubt, lean toward more reviewers. The cost of an extra review pass is low; the cost of a missed critical issue is not.

---

## Step 2: Identify what to review

Before spawning any agent, understand the subject. If the user hasn't pointed to a specific artifact, ask: *"What should I review — a file or set of files, a PR diff, a design doc, or a description you'll paste in?"*

- **Code / PR**: Explore the diff and changed files. Understand the intent before judging the approach.
- **Architecture / Design**: Read the design doc, ADR, or description. Identify the key decisions and the assumptions baked into them.
- **Documentation**: Read the document. Understand what it claims to be true and what it is trying to convey.
- **PRD / Plan**: Read the requirements. Identify what is being committed to and what is left ambiguous.

---

## Step 3: Assign adversarial roles

Each reviewer gets a distinct attack vector. Role diversity ensures coverage diversity — the panel finds different categories of problems rather than three reviewers converging on the same visible surface issue.

| Reviewer | Model | Attack Vector |
|----------|-------|---------------|
| 🔴 **The Skeptic** | `gpt-5.4` | Challenges fundamental design choices: *"Why this approach at all? What did we not consider? What problem does this actually solve, and is that the right problem?"* Targets wrong-level abstractions, missing requirements, and hidden assumptions baked into the design. |
| ⚡ **The Executioner** | `claude-sonnet-4.6` | Hunts for failure modes: *"What breaks, when, and how badly?"* Targets correctness, edge cases, error handling, race conditions, security vulnerabilities, and silent data corruption. |
| 🔨 **The Pragmatist** | `gpt-5.3-codex` | Attacks production viability: *"Will this survive real-world load, real-world teams, and real-world time?"* Targets maintainability, operability, testability, performance under stress, and the hidden long-term costs of the implementation choices. |

When using fewer than 3 reviewers:
- **1 reviewer**: Default to The Executioner (`claude-sonnet-4.6`) — correctness and failure modes are the highest-value adversarial lens for most contexts.
- **2 reviewers**: Add The Skeptic (`gpt-5.4`) — design questioning pairs well with failure-mode hunting and surfaces a different class of issue.

---

## Step 4: Launch reviewers in parallel

Spawn all reviewers simultaneously — do not wait for one to finish before starting the next. Use this subagent prompt template for each:

```
You are [ROLE NAME], an adversarial reviewer.

Your attack vector: [ATTACK VECTOR — copy from the table above]

Your posture: You are NOT here to validate this work. You are here to find everything wrong with it. Challenge the approach. Surface the failure modes. Question the assumptions. Do not soften your findings — if something is fragile, dangerous, or misguided, say so clearly and explain why.

Subject under review:
[ARTIFACT: file paths, diff, design description, or pasted content]

For each finding, provide:
- Severity: Critical / High / Medium / Low
- Category: Correctness | Design | Security | Performance | Maintainability | Observability | Other
- Issue: What is wrong, stated precisely
- Why it matters: The consequence of leaving this unaddressed
- Evidence: Where specifically in the artifact this appears (line number, section, quote)
```

If the user provided context (intent, constraints, prior decisions), include it in the subagent prompt — adversarial reviewers should challenge whether the constraints are right, not ignore them.

---

## Step 5: Synthesize findings

Once all reviewers complete, produce a unified adversarial review report:

```
# Adversarial Review — [Subject]
_Reviewed by: [list active reviewers]_

## ⚠️ Critical Issues
[Issues rated Critical by any reviewer, or convergent High issues found by 2+ reviewers.
These are blockers. Address them before proceeding.]

## 🔴 High Severity Findings
[Organized by reviewer. Cross-reference convergent findings.]

## 🟡 Medium / Low Findings
[Organized by reviewer. Do not omit these — patterns in lower-severity findings often signal systemic issues.]

## 🔗 Convergence
[Issues independently surfaced by 2 or more reviewers. These deserve the most attention —
independent adversarial reviewers reaching the same conclusion is a strong signal.]

## ⚡ Dissents
[Findings where reviewers disagreed or contradicted each other. Surface the tension.
Do not flatten genuine conflicts into silence — the disagreement itself is informative.]

## Verdict
🔴 DO NOT MERGE / DO NOT PROCEED — critical issues must be resolved first.
🟡 CONDITIONAL — specific findings must be addressed before this goes further.
🟢 PROCEED WITH CAUTION — no blockers, but findings should inform the next steps.
```

**Why convergence is the most important section:** When two or three reviewers with different models and different attack vectors independently surface the same issue, that finding is not a coincidence — it is a near-certainty. These are the issues most likely to cause real damage if ignored.

**Why dissents are preserved:** An adversarial reviewer flagging something that another dismisses is not noise — it is a tension worth the user's attention. Collapsing genuine conflicts into a majority verdict defeats the purpose of using multiple reviewers.

---

## Scope

This skill handles: complexity assessment, adversarial reviewer orchestration, parallel multi-model review execution, finding synthesis, convergence detection, and final verdict.

This skill does **not** apply fixes. Its job is to find problems, not solve them. For the remediation cycle, use the appropriate skill: `refactoring` for structural fixes, `design-patterns` for design-level recommendations, `tdd` for testability issues, `clean-code` for code quality.

When done, return control to the user.
