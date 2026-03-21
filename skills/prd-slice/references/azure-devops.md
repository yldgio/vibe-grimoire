# Azure DevOps

Always invoke the `azure-devops-cli` skill when available — it provides richer context and helper commands.

---

## Fetch the PRD

```bash
az boards work-item show --id <number>
```

If the PRD is a URL, extract the work item ID from it.

---

## Create a work item

```bash
az boards work-item create \
  --title "<title>" \
  --type "User Story" \
  --description "<body — use the template below>" \
  --project "<project-name>"
```

Capture the returned `id` — you'll need it to wire up relations.

### Add a "Blocked by" relation

Run after both the blocker and the blocked item exist:

```bash
az boards work-item relation add \
  --id <blocked-item-id> \
  --relation-type "Predecessor" \
  --target-id <blocker-item-id>
```

---

## Work item body template

Use this template for the `--description` field. Keep the content concise — reference the parent PRD rather than duplicating it.

```markdown
## Parent PRD

#<prd-workitem-number>

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior,
not a layer-by-layer breakdown. Reference specific sections of the parent PRD
rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by #<workitem-number>

Or: "None — can start immediately"

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7
```
