---
name: report-issue
description: Create a well-structured issue or bug report in the appropriate tracking system (GitHub, Azure DevOps, Jira). Use whenever a user wants to document a problem, file a bug, capture a regression, log a feature gap, or track a change request — even if they just say "log this", "create a ticket", "file a bug", "add to the backlog", or "I need to track this". Also handles issues pre-analyzed by the triage-bug skill. Adapts to any tracking system and falls back to a copyable template if no CLI is available.
---

# Report an Issue

Create a clear, actionable issue in the right tracking system. Your job is to capture and structure the problem — not to solve it. A well-written issue enables someone else to understand, reproduce, and fix the problem without asking follow-up questions.

## Process

### 1. Gather information

Read the context carefully before asking anything. Often the user has already described the problem — extract what you can from the conversation.

If you're called from `triage-bug`, the root cause analysis and TDD plan are already in context — include them in the issue body.

Only ask for missing details if they're essential for someone else to understand or reproduce the problem. Prefer one focused question over multiple sequential ones.

Key information to collect:
- **What happened** (actual behavior)
- **What should have happened** (expected behavior)
- **How to reproduce** (steps, if applicable)
- **Environment** (OS, version, runtime — only if relevant)
- **Severity / impact** (blocking? data loss? cosmetic?)

### 2. Determine the tracking system

Infer from the project setup (presence of `.github/`, `azure-devops.yml`, Jira references) or ask the user if it's ambiguous.

Then check which tool or skill is available:
- **GitHub** → use `gh-cli` skill
- **Azure DevOps** → use `az-devops-cli` skill
- **Jira** → use `jira-cli` skill
- **None available** → see Fallback below

### 3. Compose the issue

Use this template as your structure. Adapt sections to what's relevant — omit "Root Cause Analysis" and "TDD Fix Plan" for standalone reports without triage context.

---

**Title**: `[Type] Short description of the problem` (e.g., `[Bug] Login fails when email contains uppercase letters`)

**Body**:

```
## Problem

What happens (actual behavior):
What should happen (expected behavior):
How to reproduce (if applicable):

## Root Cause Analysis *(include only if pre-triaged)*

What was found during investigation:
- The mechanism of failure (describe at the module/behavior level, not file paths)
- Why the current behavior is wrong
- Any contributing factors

## TDD Fix Plan *(include only if pre-triaged)*

1. **RED**: Write a test that [describes expected behavior]
   **GREEN**: [Minimal change to make it pass]

2. ...

**REFACTOR**: [Any cleanup after tests are green]

## Acceptance Criteria

- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]
- [ ] All new tests pass
- [ ] Existing tests still pass
```

---

### 4. Add metadata

Apply labels, type, and priority consistent with the project's conventions. When in doubt, use:

| Field | Guidance |
|-------|----------|
| **Type** | `bug`, `regression`, `feature-request`, `tech-debt` |
| **Priority** | `critical` (blocking/data loss) · `high` (impairs core flow) · `medium` (workaround exists) · `low` (cosmetic) |
| **Labels** | Match project conventions; at minimum add the type label |
| **Milestone/Sprint** | Only set if clearly appropriate for the current cycle |

### 5. Create the issue

Use the appropriate CLI tool or skill. Confirm the issue was created successfully.

### Fallback (no CLI available)

If no tool is available for the tracking system, print the fully composed issue body in a copyable block and tell the user:

```
No CLI tool found for [system]. Here's the issue ready to paste:

**Title**: ...

**Body**:
...

Open a new issue at [URL if known] and paste this in.
```

## Output

After creating (or composing) the issue, print:

```
Issue: <URL or "ready to paste">
Title: <issue title>
Next step: <one line — e.g., "Assign to a team member" or "Run triage-bug to investigate root cause">
```
