---
name: github-triage
description: 'Triage of open GitHub issues and pull requests. Use when the user wants to triage, classify, or label a backlog of GitHub issues/PRs, run a repeatable triage pass, categorize items as needs-info / ready-for-agent / ready-for-human / wontfix, write agent briefs, verify bug reports or PR diffs, or drive ready-for-agent issues to a PR via an isolated worktree with worker and reviewer agents. Triggers: "triage issues", "triage the backlog", "triage", "classify open PRs", "label these issues", "/triage".'
argument-hint: 'optional: repo (owner/name), a single #issue/#PR number, or a mode (triage-only | implement-only | confirm)'
---

# GitHub Issue & PR Triage

Runs a repeatable triage pass over open GitHub issues and pull requests: classify
each untriaged item into one of four categories, act on the classification, then
drive `ready-for-agent` items to a pull request. Runs **autonomously end to end**
by default — no confirmation prompts. All `gh` CLI and `git` commands live in
[gh-commands.md](./references/gh-commands.md); this file covers the workflow logic
and spawns subagents for per-item analysis and implementation.

## What this produces

- Every untriaged open issue/PR gets exactly one category label.
- A category-appropriate comment on each item (agent brief, triage notes, or a
  close comment).
- For each `ready-for-agent` item: an isolated worktree, a drafted fix reviewed
  by a second agent, and an opened PR that references the issue.
- A final run summary table of every item touched and the action taken.

## Categories

| Label | Meaning | Action |
|-------|---------|--------|
| `needs-info` | Waiting on the reporter for more information | Post [triage notes](./references/comment-templates.md); leave open |
| `ready-for-agent` | Fully specified, ready for an AFK agent | Post an [agent brief](./references/agent-briefs.md); proceed to Phase B |
| `ready-for-human` | Needs human implementation (judgment, external access, design, manual testing) | Post an [agent-brief-shaped note explaining why it cannot be delegated](./references/comment-templates.md); leave open |
| `wontfix` | Already implemented, or rejected | Post the [matching close comment](./references/comment-templates.md) and close |

## Workflow overview

1. **Preflight** — verify `gh` auth, resolve the target repo, ensure the four labels exist.
2. **Phase A — Triage** every untriaged item, oldest first, one subagent per item.
3. **Phase B — Implement** every `ready-for-agent` item (new or pre-existing) into a PR.
4. **Summary** — report everything touched.

The full pass runs unattended and Phase B follows Phase A automatically. See
[Autonomy](#autonomy) to insert an optional review gate.

## Preflight

Verify `gh` is authenticated, resolve the target repo (the current repo unless a
repo argument is given), list existing labels, and create any of the four category
labels that are missing. If the repo already uses differently-named labels for
these concepts, map to the existing names instead of creating duplicates and
report the mapping. Commands: **Preflight** in [gh-commands.md](./references/gh-commands.md).

## Phase A — Triage untriaged items (oldest first)

List open issues and PRs that carry **none** of the four category labels, oldest
first (commands: **Phase A — list untriaged items** in
[gh-commands.md](./references/gh-commands.md)). Process them strictly oldest-first.
For each item, spawn **one subagent** (a read-only exploration subagent is ideal)
with these steps:

### 1. Gather context

- Read the full item — body, comments, existing labels, author, and dates; for a
  PR, the diff too.
- Explore the codebase for the domain concepts the item touches.

### 2. Redundancy & prior-rejection checks

- **Redundancy** — search the codebase for an existing implementation of the
  requested behavior *by domain concept*, not just the request's wording. Report
  where you looked.
- **Prior work** — scan closed issues/PRs for the same concept (commands:
  **Phase A — redundancy / prior work** in [gh-commands.md](./references/gh-commands.md)).
- If the behavior already exists, or was already rejected, the item is
  `wontfix` (skip verification, go to step 4).

### 3. Verify the claim

Do not take the claim at face value.

- **Bug** — reproduce it from the reporter's steps. Report: confirmed (name the
  code path that produces it), failed to reproduce, or insufficient detail. When
  confirmed, identify the responsible commit (`git log` / `git blame` on the code
  path) and its author's GitHub login — this becomes the issue assignee.
- **PR** — check out the branch and confirm the diff does what it claims; run the
  relevant tests or commands. Report: confirmed, failed, or insufficient detail.
- **Enhancement** — assess whether the request is specified precisely enough to
  implement without guessing.

Insufficient detail on any of the above is a strong `needs-info` signal. A
confirmed reproduction (with the code path) makes a much stronger agent brief.

### 4. Categorize and record the recommendation

Pick exactly one category using the findings:

| Finding | Category |
|---------|----------|
| Behavior already exists, or previously rejected | `wontfix` |
| Claim can't be evaluated without more from the reporter | `needs-info` |
| Fully specified and verifiable, no human-only judgment needed | `ready-for-agent` |
| Fully specified but needs human judgment, external access, design decisions, or manual testing | `ready-for-human` |

The subagent returns: category, a one-paragraph rationale citing the code path or
prior item, and the drafted comment body (brief / notes / close comment) using the
templates.

## Apply the outcome

For each item, add the category label, post the category-appropriate comment
(written to a temp markdown file to avoid shell-quoting problems), and — for
`wontfix` — close it with the reason matching *why*. Comment bodies live in
[comment-templates.md](./references/comment-templates.md); the brief spec, principles,
and examples in [agent-briefs.md](./references/agent-briefs.md); the exact commands
under **Apply the outcome** in [gh-commands.md](./references/gh-commands.md).

## Phase B — Drive `ready-for-agent` items to a PR

Runs **automatically** after Phase A, over every item labelled `ready-for-agent`
(just-labelled or triaged earlier). List them via **Phase B — list ready-for-agent**
in [gh-commands.md](./references/gh-commands.md). For each item:

1. **Isolate** — create a dedicated git worktree and branch so the main working
   tree is untouched. Follow the `using-git-worktrees` skill for placement and
   safety checks.
2. **Draft** — send a worker subagent into the worktree to implement the change,
   working from the agent brief on the issue as the authoritative spec. It must
   satisfy every acceptance-criteria checkbox in the brief.
3. **Review** — send a **separate** reviewer subagent (ideally a different agent or
   model) to check the diff against the brief's acceptance criteria and scope
   boundaries, run the tests, and report pass/fail. Loop back to the worker on
   failures until the reviewer passes or convergence stalls.
4. **Open the PR** — push the branch and open a PR. The PR body **must** reference
   the issue: `Closes #<n>` when it fully resolves the issue, or `Refs #<n>` /
   `Part of #<n>` when it addresses only part and work remains.
5. **Update the issue** — comment linking the PR and stating whether it closes or
   partially addresses the issue.
6. **Clean up** — remove the worktree once the PR is open.

Commands for this phase: **Phase B** in [gh-commands.md](./references/gh-commands.md).

## Autonomy

Runs unattended by default: it labels, comments, closes `wontfix` items, and opens
PRs without pausing, then emits the summary. Pass `confirm` (or ask to review
first) to insert **one** checkpoint — a batch plan table (`#`, type, title,
proposed label, action, close reason) shown before any write and applied only on
go-ahead. Closing items and opening PRs are the highest-impact actions; the summary
records them either way.

## Final summary

Emit a table covering every item touched: `#`, type, title, category applied,
action taken (commented / closed / PR opened with link), and any item left in
`needs-info` awaiting the reporter. Note anything skipped and why.

## Arguments / modes

- **No argument** — full autonomous pass: Phase A over all untriaged items, then
  Phase B over all `ready-for-agent` items.
- **A repo (`owner/name`)** — target that repo (`--repo owner/name`).
- **A single `#number`** — triage (and, if it lands on `ready-for-agent`, implement)
  just that item.
- **`triage-only`** — stop after Phase A.
- **`implement-only`** — skip Phase A; run Phase B over existing `ready-for-agent` items.
- **`confirm`** — add the review checkpoint before any write.

## Prerequisites

- `gh` CLI installed and authenticated.
- `git` with a clean working tree before Phase B (worktrees branch from `HEAD`).
- Permission on the repo to label, comment, close issues, and open PRs.
