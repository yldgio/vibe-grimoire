---
name: prd-slice
description: Break a PRD into independently-deliverable work items (vertical slices / tracer bullets) and create them in Azure DevOps, GitHub Issues, or Jira. Use when a user wants to convert a PRD into implementation tickets, decompose a product spec into trackable slices, create work items from requirements, or break down a PRD for any issue tracker — even if they don't say "vertical slice" or "tracer bullet".
---

# PRD Slice

Break a PRD into independently-deliverable vertical slices (tracer bullets) and push them to the right tracker.

**Tracker reference files** — use the dedicated skill when available; fall back to the reference file only when it isn't:

| Tracker       | Preferred source                          | Fallback (skill absent)          |
|---------------|-------------------------------------------|----------------------------------|
| Azure DevOps  | `azure-devops-cli` skill (if loaded)      | `references/azure-devops.md`     |
| GitHub Issues | `gh-cli` skill (if loaded)                | `references/github.md`           |
| Jira          | —                                         | `references/jira.md`             |

The dedicated skills (`gh-cli`, `azure-devops-cli`) carry richer, up-to-date platform context. When one is present in your `available_skills`, use it and skip the reference file — loading both is redundant and wastes context.

---

## Scope

**In scope:** reading a PRD from a tracker, proposing and refining vertical slices with the user, creating work items in dependency order.

**Out of scope:** writing implementation code, modifying the parent PRD, managing project boards, deciding architecture or technology choices.

---

## Process

### 1. Identify tracker and locate the PRD

If the tracker isn't already clear from context, ask the user which one they're using.

Ask for the PRD reference (work item ID, issue URL, or document path). Then fetch the PRD content using the command in the relevant reference file.

### 2. Explore the codebase (optional)

If the codebase hasn't been explored yet, do a quick scan to understand the current state — this helps size slices correctly.

### 3. Draft vertical slices

Break the PRD into **tracer bullet** work items. Each slice is a thin end-to-end cut through ALL integration layers — not a horizontal layer slice.

Slices are either:
- **HITL** — requires human interaction before proceeding (e.g. an architectural decision, a design review)
- **AFK** — can be implemented and merged without human interaction

Prefer AFK slices where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which PRD user stories this addresses

Ask the user:
- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the HITL / AFK labels right?

Iterate until the user approves the breakdown.

### 5. Create work items

For GitHub and Azure DevOps, check whether the matching skill (`gh-cli` or `azure-devops-cli`) is in your `available_skills`. If it is, use it — no need to also load the reference file. If it isn't, read `references/<tracker>.md` for commands and the issue body template. For Jira, always read `references/jira.md`.

Create work items in **dependency order** (blockers first) so you can reference real IDs in the "Blocked by" field.

Do NOT close or modify the parent PRD work item.

The skill's work is complete when all approved slices have been created in the tracker and the user has the issue numbers. Return control to the user.
