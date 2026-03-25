# GitHub Issues

Always invoke the `gh-cli` skill when available — it provides richer context and helper commands.

---

## Fetch the PRD

```bash
gh issue view <number>
```

If the PRD is a URL, extract the issue number from it. For a URL like
`https://github.com/owner/repo/issues/42`, the number is `42`.

---

## Create an issue

Always pass `--repo OWNER/REPO` explicitly. Without it, `gh` targets whatever
repository the current working directory is set to, which may not be the
project you are slicing.

```bash
gh issue create \
  --repo OWNER/REPO \
  --title "<title>" \
  --body "<body — use the template below>" \
  --label "enhancement"
```

If the issue is blocked by an existing issue, add `--blocked-by <number>`:

```bash
gh issue create \
  --repo OWNER/REPO \
  --title "<title>" \
  --body "<body — use the template below>" \
  --label "enhancement" \
  --blocked-by <blocker-issue-number>
```

> **Note:** `--blocked-by` and `--blocking` accept issue numbers from the
> **same repository** only. Cross-repo blocking is not supported by the `gh`
> CLI; document cross-repo dependencies in the issue body instead.

Use `--blocking <number>` for the inverse direction — when the new issue blocks an existing one.

Capture the returned issue URL or number — you'll need it to wire up blockers for subsequent issues.

---

## Issue body template

Use this template for the `--body` field. Keep the content concise — reference the parent PRD rather than duplicating it.

```markdown
## Parent PRD

#<prd-issue-number>

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior,
not a layer-by-layer breakdown. Reference specific sections of the parent PRD
rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7
```
