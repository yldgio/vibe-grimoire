# Jira

> **Status: stub — not yet implemented.**
> Jira support is planned. When this file is populated, it will follow the same
> structure as `azure-devops.md` and `github.md`.

---

## Planned coverage

- Fetch a PRD (Epic or Story) by key or URL
- Create issues via the Jira REST API or CLI
- Link issues with "is blocked by" link type
- Issue body template aligned with the common format

---

## In the meantime

If you need Jira support today, ask the user to provide:
1. The Jira project key (e.g. `PROJ`)
2. The parent PRD issue key (e.g. `PROJ-123`)
3. Their preferred issue type (Story, Task, Sub-task)

Then create issues manually via the Jira UI or REST API, following the body
template pattern from `azure-devops.md` or `github.md`.
