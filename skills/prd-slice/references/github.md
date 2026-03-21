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

```bash
gh issue create \
  --title "<title>" \
  --body "<body — use the template below>" \
  --label "enhancement"
```

Capture the returned issue URL or number — you'll need it to wire up blockers.

### Indicate a "Blocked by" relationship

GitHub does not have native blocking links. Use body references instead:

- Reference the blocker in the body: `Blocked by #<number>`
- If the repo uses a project board with a "Blocked by" custom field, set it via:

```bash
gh project item-edit --id <item-id> --field-id <blocked-by-field-id> --text "#<blocker-number>"
```

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

## Blocked by

- Blocked by #<issue-number>

Or: "None — can start immediately"

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7
```
