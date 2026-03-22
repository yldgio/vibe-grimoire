---
name: triage-bug
description: Investigate a bug or unexpected behavior by tracing the root cause through the codebase, then produce a TDD-based fix plan. Use this whenever a user reports a bug, crash, or wrong behavior — even if they say "something is off", "this broke", "not working", "why is X happening", "investigate this", or paste an error message. Also use when the user asks to trace a regression, understand a failure, or plan a fix. This is a hands-off deep-dive that ends with a tracked issue and a concrete fix plan.
---

# Triage with TDD

Investigate a reported problem, find its root cause, and produce a TDD fix plan. The goal is to hand the user a clear, actionable issue they can immediately start working on. Minimize back-and-forth — code exploration answers most questions faster than asking.

## Process

### 1. Capture the problem

If the user hasn't described the issue, ask exactly one question: "What's the problem you're seeing?"

Resist asking follow-ups before you investigate. You'll find most of the context yourself, and what you can't find you can clarify at the end.

### 2. Explore and diagnose

Launch parallel explore subagents to investigate different angles simultaneously — this saves significant time on larger codebases. A good split:

- **Subagent A — Code path**: Trace from the symptom back to its origin. Follow the call chain, data flow, or event lifecycle until you find where the behavior diverges from what's expected.
- **Subagent B — History & tests**: Check git log on relevant files for recent changes. Look at existing tests to understand what's already verified and what's missing.
- **Subagent C (if needed) — Similar patterns**: Search the codebase for analogous features that work correctly. This reveals whether the issue is unique or systemic.

For small, focused bugs a single subagent is fine — use your judgment on scope.

Your investigation should surface:

- **Where** the bug manifests (entry point, UI, API, data layer)
- **What** code path is involved
- **Why** it fails — the root cause, not just the symptom
- **Whether** it's a regression, missing guard, design flaw, or missing feature

### 3. Assess and synthesize

Summarize what you found:

- Root cause (be specific about the mechanism, not just the location)
- Confidence level: high / medium / low — be honest if investigation was incomplete
- Type: regression | missing feature | design flaw | edge case | environmental
- Minimal fix scope: which modules or contracts need to change

Keep descriptions at the module/behavior level. Avoid file paths and line numbers — the issue should stay useful even after the code is reorganized.

### 4. Design TDD fix plan

Create an ordered list of RED-GREEN cycles. Each cycle is one vertical slice of the fix:

- **RED**: Describe a specific test that captures the broken or missing behavior
- **GREEN**: Describe the minimal code change that makes that test pass

Good cycles:
- Test through public interfaces, not implementation internals — so they survive refactors
- Assert on observable outcomes (API responses, UI state, return values), not internal state
- Each cycle stands alone — implement one before writing the next

Aim for 2–5 cycles. One is a sign the problem is too narrow; more than five suggests the scope should be split.

End with a **REFACTOR** note if any cleanup would be valuable once the tests are green.

### 5. File the issue

Call the `report-issue` skill with the full triage context: root cause, fix type, TDD plan, and acceptance criteria. The `report-issue` skill will handle formatting and submission to the appropriate tracking system.

### Output

Once the issue is created, print:

```
Issue: <URL>
Root cause: <one sentence>
Fix: <N> RED-GREEN cycles — first test: <brief description of RED #1>
```