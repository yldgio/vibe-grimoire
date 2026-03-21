---
name: refactoring-plan
description: >-
  Create a detailed refactor plan with tiny commits via user interview, then
  submit it as a GitHub issue, Azure DevOps work item, or local file. Use when
  the user wants to plan a refactor, write a refactoring RFC, break a codebase
  change into safe incremental steps, reduce technical debt, clean up code,
  restructure or reorganize a module, rename/move/extract/consolidate
  components, or says things like "this is a mess", "I need to untangle this",
  "before I start let's plan", "how do I safely change this without breaking
  things", or "I want to pay down some tech debt".
---

# Refactoring Plan

Guide the user from a messy codebase problem to a fully-formed refactor plan, broken into the smallest safe commits possible, then submit it to their preferred destination.

**Skill workflow** — these skills chain naturally:
[`pre-mortem`](#) *(optional — stress-test the plan before committing)* → **`refactoring-plan`** → [`prd-slice`](#) *(push slices to a tracker)*

---

## Process

### 1. Gather the problem statement

Ask the user for a detailed description of:
- The problem they are trying to solve
- Any ideas or constraints they already have in mind

Understanding the pain before proposing solutions matters — jumping straight to answers often misses what's really broken.

### 2. Explore the codebase

Use a subagent to explore the repo and verify the user's assertions. Understand the current architecture, module boundaries, and potential integration points.

Focus on:
- What the affected code does and who calls or depends on it
- Existing test coverage in the area (test files, gaps, patterns used)
- The blast radius of the proposed change — what else could break

### 3. Present alternative approaches

Before committing to a direction, make sure the user has considered the full range of options. Refactoring strategy choice has a huge impact on risk and rollout complexity — presenting alternatives leads to better, more deliberate decisions.

Consider offering:
- **Strangler Fig** — wrap the old code with new code gradually, replacing piece by piece while both versions coexist
- **Extract and Delegate** — pull functionality into a new module without changing any call sites first, then migrate callers incrementally
- **Parallel Implementation** — build the new version alongside the old, then swap with a single cut-over commit
- **Incremental Rename/Move** — change names or locations in tiny steps, keeping deprecated aliases until all callers are updated
- **Big-Bang Rewrite** — only viable if scope is truly isolated, test coverage is solid, and the blast radius is small

For each option, briefly explain the tradeoff so the user can make an informed choice.

### 4. Interview the user about the implementation

Before writing the plan, resolve every material decision. Ambiguities caught here cost minutes; ambiguities discovered mid-refactor cost days. Cover:

- **Scope** — exactly which modules, classes, or interfaces are in play
- **Backwards compatibility** — do existing call sites need to keep working during the transition?
- **Branching and deployment** — feature flags? long-lived branch? trunk-based incremental commits?
- **Downstream consumers** — other services, packages, or teams that depend on the code being changed
- **Rollback strategy** — what does "undo" look like if something breaks in production?
- **Test ownership** — who is responsible for writing or updating the tests?

### 5. Nail down the exact scope

Work out precisely what will change and, equally important, what will **not** change. Explicit out-of-scope decisions are as valuable as the plan itself — they prevent scope creep and protect the timeline.

### 6. Check test coverage

Look in the codebase for tests covering the code being changed. Insufficient test coverage is the leading cause of refactor regressions — a refactor that breaks undetected behavior is worse than no refactor at all.

If coverage is thin, ask: *"Before we touch this code, should the first commit be tests that lock in the current behavior?"* This is often the right first step.

### 7. Break into tiny commits

Break the implementation into the smallest possible commits. Each commit should:
- Leave the codebase in a working state (tests pass, app runs)
- Be independently reviewable and revertable
- Have a clear, descriptive commit message

Martin Fowler: *"Make each refactoring step as small as possible, so that you can always see the program working."*

If a step feels large, split it again.

### 8. Submit the plan

Ask the user where they want it saved: **GitHub**, **Azure DevOps**, or **local file**.

Use a subagent to submit — this keeps your main context clean:
- **GitHub**: Use the `gh-cli` skill (`gh issue create`) with appropriate labels and assignees.
- **Azure DevOps**: Use the `az-devops-cli` skill (`az boards work-item create`) with appropriate tags and assignees.
- **Local file**: Save to `./plans/<feature-name>-refactor.md`.

Use the template below for the body.

<refactor-plan-template>

## Problem Statement

The problem the developer is facing, from their perspective.

## Solution

The chosen approach and why it was selected over the alternatives considered.

## Commits

A detailed, step-by-step implementation plan broken into the tiniest commits possible. Each commit should leave the codebase in a working state.

## Decision Document

Key decisions made during planning. Include:

- Modules being built or modified
- Interface changes
- Architectural decisions
- Schema changes
- API contracts
- Backwards compatibility decisions
- Rollback strategy

Omit specific file paths and code snippets — they become stale quickly and will mislead future readers who encounter them out of context. Describe intent and structure, not implementation detail.

## Testing Decisions

- What makes a good test for this change (test external behavior, not implementation details)
- Which modules will be tested
- Prior art — similar tests already in the codebase to use as a model

## Out of Scope

Everything explicitly excluded from this refactor. Being precise here is as important as defining what is in scope.

## Further Notes *(optional)*

Any additional context, open questions, or follow-up considerations.

</refactor-plan-template>