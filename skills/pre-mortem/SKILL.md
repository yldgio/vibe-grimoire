---
name: pre-mortem
description: >-
  Run a pre-mortem on a plan, idea, or PRD: stress-test a design by assuming it
  failed, then relentlessly interrogate every branch of the decision tree to
  find out why so the user can fix it before implementation starts. Two modes: (1) idea/plan
  exploration — no document yet, use pre-mortem to surface implications and
  shape a design; (2) PRD stress-test — an existing PRD or design doc, use
  pre-mortem to expose contradictions, missing assumptions, and functional
  ramifications. Use when the user wants to stress-test a plan, asks you to
  "ask me", says "interrogami" or "fammi domande", mentions "pre-mortem",
  "design of design", or wants rigorous design discovery before implementation.
---

# Pre-mortem

Stress-test a plan before implementation so hidden assumptions fail on paper, not in execution.

**Skill workflow** — pre-mortem can be used standalone or as a gate between steps:
[`create-prd`](#) *(gather requirements)* → **`pre-mortem`** *(stress-test before building)* → [`plan-from-prd`](#) *(turn it into implementation phases)*

## Two modes

**Mode 1 — Idea exploration**: The user has an idea, not yet a document. Interview them relentlessly to surface assumptions, constraints, and design implications. Help them reach a first draft design.

**Mode 2 — PRD stress-test**: The user has an existing PRD, plan, or design doc. Read it first, then interrogate every assumption, surface contradictions, and explore functional ramifications they may not have considered.

In both modes: start with the context already available — current documents, prior decisions, and relevant codebase context. Then walk down each unresolved branch of the design tree, resolving dependencies between decisions one-by-one. For each unresolved question, provide your recommended answer.

If a question can be answered by exploring the codebase or existing documents, do that before asking the user. Use subagents for codebase exploration or external research so the main thread stays focused on the pre-mortem.

When you need input from the user, ask one question at a time. Don't move on to the next question until the current one is resolved. If the user gives an answer that raises new questions, explore those before moving on.

## Complexity challenge

When the scope of what emerges feels large — many moving parts, cross-cutting concerns, or a broad user-facing surface area — challenge the user to identify a first sufficient MVP wave before exploring all edge cases. Ask: *"What is the smallest version of this that delivers real value?"* Encourage decomposing the work into successive waves rather than attempting a complete solution upfront.

## Output

Always produce a written summary of findings. Recommend the output format that best fits the situation, and ask the user to choose when both are viable:

- A **separate findings/risk document** (recommended for PRD stress-tests and idea exploration): saved as `{feature}-premortem.md`
- An **annotated version** of the existing document (recommended for living designs when a PRD or design doc already exists): highlights risks inline

Never apply implementation changes to the codebase directly from this skill. You may create the findings document or annotate the design artifact. Return control to the user once the chosen output is saved.
