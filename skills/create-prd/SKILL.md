---
name: create-prd
description: Create a PRD through user interview, codebase exploration, and module design, then submit as a GitHub issue, Azure DevOps work item, or local file. Use when the user wants to create or write a PRD, create a product requirements document, design a new feature, or capture requirements.
---

# Create PRD

Guide the user from a problem statement to a fully-formed PRD, then submit it to their preferred destination.

**Skill workflow** — these skills chain naturally:
`create-prd` → [`pre-mortem`](#) *(optional stress-test)* → [`plan-from-prd`](#) *(phased plan)* → [`prd-slice`](#) *(tracker work items)*

---

## Process

### 1. Gather the problem statement

Ask the user for a detailed description of:
- The problem they are trying to solve
- Any ideas or constraints they already have in mind

### 2. Explore the codebase

Use a subagent to explore the repo and verify the user's assertions. Understand the current architecture, existing patterns, and potential integration points.

### 3. Interview the user

Relentlessly interview the user about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

> Tip: Invoke the `pre-mortem` skill for deeper design stress-testing before committing to decisions.

### 4. Design modules *(optional — skip if the user wants a lightweight PRD)*

Sketch the major modules to build or modify. Actively look for opportunities to extract **deep modules** — ones that encapsulate significant functionality behind a simple, stable, testable interface.

Review with the user:
- Do these modules match their expectations?
- Which modules should have tests written for them?

### 5. Write the PRD

Use the `<prd-template>` below to write the PRD.

### 6. Submit the PRD

Ask the user where they want it saved: **GitHub**, **Azure DevOps**, or **local file**.

Run a subagent to submit so you keep your main context clean:
- **GitHub**: Use the `gh-cli` skill (`gh issue create`) with appropriate labels and assignees.
- **Azure DevOps**: Use the `azure-devops-cli` skill (`az boards work-item create`) with appropriate tags and assignees.
- **Local file**: Save to `./prds/<feature-name>.md`.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>