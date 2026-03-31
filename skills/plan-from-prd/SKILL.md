---
name: plan-from-prd
description: Turn a PRD into a multi-phase, local Markdown implementation plan using tracer-bullet vertical slices, saved to ./plans/. Use when the user wants to create an implementation plan from a PRD, plan phases from a PRD, break a PRD into development phases, or mentions "tracer bullets" or "implementation phases". For creating tracker work items (GitHub Issues, Azure DevOps, Jira) use the prd-slice skill instead.
---

# Plan from PRD

Turn a PRD into a phased implementation plan using vertical slices (tracer bullets). Output is a local Markdown file in `./plans/`.

**Skill workflow** — this skill fits in the middle:
[`create-prd`](#) → [`pre-mortem`](#) *(optional)* → **`plan-from-prd`** → [`prd-slice`](#) *(push slices to a tracker)*

> **Not what you need?** If you want to create GitHub Issues / Azure DevOps work items / Jira tickets directly from the PRD, use `prd-slice` instead.

## Process

### 1. Confirm the PRD is in context

The PRD should already be in the conversation. If it isn't, ask the user to paste it or point you to the file.

### 2. Explore the codebase

If you have not already explored the codebase, do so with a subagent to understand the current architecture, existing patterns, and integration layers.

### 3. Identify durable architectural decisions

Before slicing, identify high-level decisions that are unlikely to change throughout implementation:

- Route structures / URL patterns
- Database schema shape
- Key data models
- Authentication / authorization approach
- Third-party service boundaries

These go in the plan header so every phase can reference them.

### 4. Draft vertical slices

Break the PRD into **tracer bullet** phases. Each phase is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- Do NOT include specific file names, function names, or implementation details that are likely to change as later phases are built
- DO include durable decisions: route paths, schema shapes, data model names
</vertical-slice-rules>

When the PRD is large or complex — many stories, broad surface area, or multiple cross-cutting concerns — group phases into **waves**. The first wave must deliver a demonstrable, MVP-sufficient experience on its own. Subsequent waves add depth and breadth. When grouping phases within a wave, prefer phases that share no blocking dependencies so they can proceed in parallel.

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each phase show:

- **Title**: short descriptive name
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Should any phases be merged or split further?
- If waves were proposed: does Wave 1 represent a sufficient MVP? Are the wave boundaries right?

Iterate until the user approves the breakdown.

### 6. Write the plan file

Create `./plans/` if it doesn't exist. Write the plan as a Markdown file named after the feature (e.g. `./plans/user-onboarding.md`). Use the template below.

<plan-template>
# Plan: <Feature Name>

> Source PRD: <brief identifier or link>

## Architectural decisions

Durable decisions that apply across all phases:

- **Routes**: ...
- **Schema**: ...
- **Key models**: ...
- (add/remove sections as appropriate)

---

<!-- If wave grouping was agreed with the user, wrap phases inside ## Wave N sections.
     Omit wave headers for simple features. -->

## Wave 1: MVP *(omit wave headers if no wave grouping)*

## Phase 1: <Title>

**User stories**: <list from PRD>

### What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

### Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Phase 2: <Title>

**User stories**: <list from PRD>

### What to build

...

### Acceptance criteria

- [ ] ...

---

## Wave 2: <Label> *(omit if no wave grouping)*

## Phase 3: <Title>

**User stories**: <list from PRD>

### What to build

...

### Acceptance criteria

- [ ] ...

<!-- Repeat phases and waves as needed -->
</plan-template>

The skill's work is complete when the plan file is saved and the user has confirmed the phase breakdown. Return control to the user.