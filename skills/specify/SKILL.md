---
name: specify
description: >-
  Guide the user through a structured specification process: define the goal,
  specify exactly what to build (and what NOT to build), and establish measurable
  evaluation criteria — all before implementation begins. Produces a living spec
  document. Use when the user has a goal or feature idea and wants to define the
  spec, says "specify this", "what's the spec", "define the specification",
  "how do I achieve this goal", "break this down", "what do I need to build",
  "write a spec", "define requirements", wants to create a specification with
  verification criteria, or has just finished using the-goal and wants to turn
  the goal into a precise, implementable specification. Also use when the user
  wants to define evaluation criteria before coding, or mentions "adversarial
  verification", "quality criteria", or "acceptance criteria".
---

# Specify

Guide the user through a structured specification in three phases — **Goal**, **Specification**, **Evaluation Criteria** — producing a single living document that defines exactly what to build, what not to build, and how to verify the result.

**Skill workflow:**
[`the-goal`](#) *(find the real goal)* → **`specify`** *(define the specification)* → implementation

---

## Core behavior

### Interview pattern — the same in every phase

All three phases use the same interview approach:

Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. Ask one question at a time using your runtime's interactive prompt tools. Before each question, show your **preference ranking**: list the likely answers ordered by your recommendation (best first), with a one-sentence reason for your top pick. Offer these as choices when prompting the user.

After each answer, restate the decision explicitly and confirm before moving on. Never assume — verify.

### Scope discipline — enforced in every phase

Monitor the growing specification continuously. When the document becomes too large — too many features, too many tasks, too many evaluation criteria — push back hard. Insist that scope must be reduced. The user decides *what* to cut, but you insist that *something* must go. Challenge with:

- *"This is growing beyond what can be built and verified reliably. Which of these can we leave out of this spec and handle separately?"*
- *"Can this be two specs instead of one? What's the minimum that delivers the goal?"*

This applies equally across all three phases. A goal that's too broad, a feature list that's too long, or an evaluation plan that's too complex — all get the same pushback.

---

## Phase 1: Goal

Establish the goal using the interview pattern above. If a goal document already exists from a prior `the-goal` session, read it and confirm with the user. If the user has a rough idea but no document, interview to extract:

- **What & Why** — the goal and why it matters
- **Done Looks Like** — the finished behavioral state: user journeys, observable outcomes (not feature names)
- **Boundaries** — what is explicitly out of scope

If the goal is genuinely vague or too broad, recommend running `the-goal` skill first rather than trying to specify something unclear.

Push back if the goal tries to solve multiple problems at once: *"Is this one goal or several? Which single outcome matters most?"*

---

## Phase 2: Specification

Before interviewing, explore the codebase with a subagent to understand the existing landscape — architecture, patterns, schemas, testing frameworks, relevant modules. Come prepared with context so the user doesn't have to explain what you can discover yourself.

Then interview through each section, one at a time:

### a. Scope Boundaries

Now that the goal is defined, draw the line. Interview to establish:

- **In scope** — what will be built, changed, or delivered
- **Out of scope** — what will NOT be built, with a reason for each exclusion

Every boundary must be a conscious decision. Challenge anything implicit: *"You didn't mention X — is that intentionally out of scope, or did we miss it?"* Nothing is assumed in or out — everything is explicitly stated.

### b. Constraints & Assumptions

What are we building with and within? Interview to separate:

- **Hard constraints** (non-negotiable) — tech stack, API rate limits, performance requirements, security mandates, deployment targets
- **Assumptions** (believed true but not verified) — library behavior, data volumes, user behavior patterns

For each assumption, ask: *"What happens if this turns out to be wrong? Should we verify this first?"*

### c. Decisions Already Made

What's already decided and shouldn't be revisited? Document:

- Database schemas in use
- Encryption standards
- Architectural patterns
- API contracts
- Naming conventions
- Library choices

These are guardrails. They constrain the solution space and prevent the implementer from relitigating settled decisions.

### d. Task Breakdown

Decompose the work into discrete, independently verifiable sub-tasks. Each task is a checkpoint — a clear deliverable. Interview to ensure each task is:

- **Small enough** to complete and verify in a single session
- **Independent enough** to verify on its own
- **Concrete enough** to know when it's done
- **Ordered** so each builds on the last, with blockers marked

These are the deliverables. Each one should be demoable or verifiable on its own.

---

## Phase 3: Evaluation Criteria

This phase defines how to verify the implementation is correct — **before any code is written**. The criteria become the quality contract.

Interview the user to define two categories of checks:

### a. Deterministic checks

Automated, pass/fail verification that runs without judgment:

- Scripts or commands that produce a clear pass/fail
- Schema validations
- Test assertions
- Output comparisons
- Performance thresholds (response time < Xms, memory < Y MB)

For each task in the breakdown, ask: *"What's a concrete check that proves this task is done correctly?"* Push hard toward deterministic checks — they're cheaper, faster, and more reliable than judgment.

### b. LLM-as-judge criteria

For aspects that can't be automated, define measurable rubrics that a model can evaluate. Each criterion must have:

- **Question** — a clear question the judge must answer (e.g., "Does the error message explain what went wrong and how to fix it?")
- **Evidence** — what the judge should examine (e.g., "Read all error messages produced by the module")
- **Scale** — a measurable threshold or rubric (e.g., "1–5 scale where 5 = message explains cause, consequence, and fix action")
- **Pass boundary** — minimum score to pass (e.g., "≥ 4")

For every criterion the user describes subjectively, push to make it measurable: *"How would you score this on a 1–5 scale? What's the minimum acceptable score?"*

### c. Adversarial verification protocol

The spec must instruct that verification is adversarial: the model that implements is NOT the model that verifies. Include in the spec:

- The verifier evaluates against the criteria defined above
- The verifier produces a verdict for each criterion (pass/fail with evidence)
- The verifier identifies issues the implementer should address

### d. Convergence criterion

Define when the implementation loop should stop. The implementing agent keeps iterating as long as further modifications are cost-effective — that is, the expected improvement in evaluation score justifies the cost of another iteration. The spec should define:

- **Quality floor** — minimum scores that must be met (hard stop below this)
- **Diminishing returns signal** — e.g., "Stop when the last iteration improved less than N% on any criterion"
- **Maximum iterations** — an upper bound to prevent infinite loops

---

## Output

Write the specification using the template below. Save to `./specs/<feature-name>.md`. Create the `./specs/` directory if it doesn't exist.

Present the complete spec to the user for final review. Ask:
- *"Does each section accurately capture what we discussed?"*
- *"Are there gaps — things we know but didn't cover?"*
- *"Are the evaluation criteria tight enough to catch real problems?"*

Iterate until the user confirms. Remind them this is a living document — update it as implementation reveals new information.

<spec-template>

# Spec: <Feature Name>

> Goal: <one-line goal statement>
> Date: <date>
> Status: Draft | Active | Complete

---

## What & Why

The goal and why it matters.

## Done Looks Like

The finished behavioral state. Describe as user journeys and observable outcomes:

- Outcome 1 — description of observable behavior
- Outcome 2 — description of observable behavior

---

## Scope

### In Scope

- Item — description
- Item — description

### Out of Scope

- Item — *reason for exclusion*
- Item — *reason for exclusion*

---

## Constraints & Assumptions

### Hard Constraints

- Constraint — description

### Assumptions

- Assumption — *what happens if wrong*

---

## Decisions Already Made

| Decision | Rationale |
|----------|-----------|
| Decision | Why |

---

## Task Breakdown

### Task 1: <Name>

- **Depends on**: none
- **Description**: what to do
- **Done when**: observable completion criterion

### Task 2: <Name>

- **Depends on**: Task 1
- **Description**: what to do
- **Done when**: observable completion criterion

---

## Evaluation Criteria

### Deterministic Checks

| Check | Task | How to run | Pass condition |
|-------|------|------------|----------------|
| Name | Task N | Command/script | Expected result |

### LLM-as-Judge Criteria

| Criterion | Task | Question | Evidence to examine | Scale | Pass boundary |
|-----------|------|----------|---------------------|-------|---------------|
| Name | Task N | Question the judge answers | What to look at | 1–5 scale definition | ≥ N |

### Verification Protocol

- **Adversarial**: The verifying model MUST be different from the implementing model.
- **Process**: Verifier evaluates every criterion above, produces pass/fail with evidence for each, and identifies issues for the implementer.

### Convergence

- **Quality floor**: All deterministic checks pass. All LLM-as-judge criteria meet their pass boundary.
- **Diminishing returns**: Stop when the last iteration improved less than <N>% on any criterion.
- **Max iterations**: <N>

</spec-template>

The skill's work is complete when the spec has been saved and the user has confirmed it. Return control to the user.
