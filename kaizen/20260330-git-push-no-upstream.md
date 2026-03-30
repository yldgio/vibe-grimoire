# `git push origin <branch>` does not set upstream tracking

**Date**: 2026-03-30 | **Context**: cherry-pick + push on `anvil/add-the-immortals-agents`

## What happened

After cherry-picking a fix commit and running `git push origin anvil/add-the-immortals-agents`,
the branch appeared up-to-date but `git branch -vv` showed no `[origin/...]` tracking annotation.
The user asked "is the current branch linked to the remote?" — revealing the gap.

## Why it was wrong

`git push origin <branch>` pushes the commits but does **not** configure the upstream tracking
reference. Only `git push -u origin <branch>` (or `--set-upstream`) writes the tracking metadata.
Without it, `git pull`, `git status` ahead/behind counts, and CI tooling that checks tracking
all fail silently or produce confusing output.

## What to do instead

Always use one of these when pushing a branch for the first time (or after a cherry-pick to an
untracked branch):

```bash
git push -u origin <branch>          # push + set upstream in one step
# or, after a bare push:
git branch --set-upstream-to=origin/<branch>
```

Verify with `git branch -vv` — the branch line must show `[origin/<branch>]`.

## Rule to remember

> After any `git push` on a branch that has no `[origin/…]` in `git branch -vv`,
> follow up with `git push -u origin <branch>` or `git branch --set-upstream-to`.
