# Design: Documentation & Install for The Immortals

## Decisions

| Branch | Decision |
|--------|----------|
| Doc scope | Full overhaul: 6 new skills + full Agents section + council usage guide |
| Install approach | Dedicated `install-immortals.sh` + `install-immortals.ps1` |
| Agent install target | `.github/agents/` (Copilot CLI native) |
| Conflict handling | Ask before overwriting |
| Install source | `curl` from `yldgio/vibe-grimoire` on GitHub |
| README agent depth | Full section: table + role/specialty + usage examples |
| Multi-platform docs | `docs/installing-agents.md` (linked from README) |

---

## Files to Create/Modify

| File | Action | Risk |
|------|--------|------|
| `README.md` | Update — add 6 skills + Agents section + install guide | 🟡 |
| `install-immortals.sh` | Create — bash install script | 🟢 |
| `install-immortals.ps1` | Create — PowerShell equivalent | 🟢 |
| `docs/installing-agents.md` | Create — manual install for Claude Code + OpenCode | 🟢 |

---

## README Additions

### New skills to document (same format as existing entries)

- `design-patterns` — Fowler/GoF catalog, pattern selection, misuse detection
- `clean-code` — Naming audits, SOLID, function shape (Uncle Bob)
- `refactoring` — Behavior-preserving moves, Fowler's catalog
- `domain-driven-design` — Strategic design, bounded contexts, aggregates, ubiquitous language (Evans)
- `performance-review` — Complexity, I/O, profiling strategy (Linus)
- `the-immortals` — Orchestrator routing: Solo / Duo / Full Council

### New Agents section (after Skills)

- Intro paragraph explaining the concept
- Table: 5 members + orchestrator (name | alias | specialty | persona note)
- Usage examples: `@fowler`, `@the-immortals`, full council escalation
- Install snippet linking to `install-immortals.sh` / `.ps1`
- Link to `docs/installing-agents.md` for Claude Code and OpenCode

### Badge update

`[![Skills](https://img.shields.io/badge/skills-17-blue)]` → `skills-23`

---

## Install Script Behaviour

```
1. Download 6 SKILL.md files  → .agents/skills/<name>/SKILL.md
2. Download 6 agent .md files → .github/agents/<name>.agent.md
3. For each file: if exists   → prompt "Overwrite [path]? [y/N]"
4. Print summary: N skills installed, M agents installed, K skipped
5. Print footer: "For Claude Code & OpenCode, see docs/installing-agents.md"
```

Source URL pattern:
```
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/<name>/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/<name>.agent.md
```

Skills installed by the script:
- `design-patterns`
- `clean-code`
- `refactoring`
- `domain-driven-design`
- `performance-review`
- `the-immortals`

Agents installed by the script:
- `fowler.agent.md`
- `beck.agent.md`
- `uncle-bob.agent.md`
- `evans.agent.md`
- `linus.agent.md`
- `the-immortals.agent.md`

---

## `docs/installing-agents.md` Content Outline

| Section | Content |
|---------|---------|
| GitHub Copilot CLI | Native: `.github/agents/` — use `install-immortals.sh` or `.ps1` |
| Claude Code | No native agents path. Workaround: paste persona into `CLAUDE.md` as a named section; include the `## How you work` block as a system-prompt snippet. |
| OpenCode | No equivalent agent format. Use skills via `.agents/skills/` — the-immortals SKILL.md provides routing logic. |

---

## Notes & Risks

1. **`curl` on Windows**: `.ps1` must use `Invoke-WebRequest`, not `curl` (which is a PS alias with different syntax).
2. **Branch vs main**: Scripts default to `main`. During this PR (`anvil/add-the-immortals-agents`), the README install snippet can point to `main` since the branch will merge.
3. **`the-immortals-design.md`**: Link from README as the authoritative design reference.
4. **Badge count**: Update skill count badge from 17 → 23 in README header.
