# gh & git Commands

Concrete commands for the github-triage workflow. All GitHub reads and writes use
the `gh` CLI; Phase B isolation uses `git worktree`. Commands target the current
repo — add `--repo owner/name` to target another. Single-quote `--search` strings
so they pass through PowerShell unchanged. Write comment bodies to a temp markdown
file and pass them with `--body-file` to avoid shell-quoting problems.

## Preflight

```bash
gh auth status                                        # must be authenticated
gh repo view --json nameWithOwner --jq .nameWithOwner # resolve the current repo
gh label list --limit 200                             # see which labels already exist
```

Create any missing category labels:

```bash
gh label create needs-info      --color FBCA04 --description "Waiting on the reporter for more information"
gh label create ready-for-agent --color 0E8A16 --description "Fully specified, ready for an AFK agent"
gh label create ready-for-human --color 1D76DB --description "Needs human implementation"
gh label create wontfix         --color E11D21 --description "Already implemented or rejected"
```

## Phase A — list untriaged items (oldest first)

```bash
gh issue list --state open \
  --search 'sort:created-asc -label:needs-info -label:ready-for-agent -label:ready-for-human -label:wontfix'
gh pr list --state open \
  --search 'sort:created-asc -label:needs-info -label:ready-for-agent -label:ready-for-human -label:wontfix'
```

## Phase A — read one item

```bash
gh issue view <n> --comments
gh pr view <n> --comments
gh pr diff <n>
```

## Phase A — redundancy / prior work

```bash
gh issue list --state closed --search '<domain terms> sort:updated-desc'
gh pr list    --state closed --search '<domain terms> sort:updated-desc'
```

## Apply the outcome

```bash
# ready-for-agent
gh issue edit <n> --add-label ready-for-agent
gh issue comment <n> --body-file brief.md

# ready-for-human
gh issue edit <n> --add-label ready-for-human
gh issue comment <n> --body-file human-brief.md

# needs-info
gh issue edit <n> --add-label needs-info
gh issue comment <n> --body-file triage-notes.md

# wontfix (already implemented OR rejected) — comment, then close
gh issue edit <n> --add-label wontfix
gh issue close <n> --reason "not planned" --body-file wontfix.md
```

For PRs, use `gh pr edit`, `gh pr comment`, and `gh pr close`.

## Phase B — list ready-for-agent

```bash
gh issue list --state open --search 'label:ready-for-agent sort:created-asc'
```

## Phase B — implement one item

```bash
git worktree add ../<repo>-issue-<n> -b fix/issue-<n>
# worker + reviewer subagents implement and verify inside the worktree, then commit and push
gh pr create --title "<concise title>" --body-file pr-body.md --head fix/issue-<n>
git worktree remove ../<repo>-issue-<n>
```

The PR body **must** reference the issue: `Closes #<n>` for full resolution, or
`Refs #<n>` / `Part of #<n>` when work remains.
