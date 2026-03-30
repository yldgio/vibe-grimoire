# Installing The Immortals Agents

The Immortals are 5 legendary dev-persona agents — Martin Fowler, Kent Beck, Robert C. Martin, Eric Evans, and Linus Torvalds — plus 1 orchestrator that routes tasks to the right expert (or a council of them). Each AI coding runtime handles agent installation differently. This guide covers all of them.

---

## Quick Install

The fastest path — run one script and all agents + skills land in the right places for your OS:

```bash
# macOS / Linux
bash <(curl -fsSL https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/install-immortals.sh)

# Windows (PowerShell)
iex (iwr -UseBasicParsing https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/install-immortals.ps1).Content
```

The scripts install:
- Agent files → `.github/agents/` (picked up by GitHub Copilot CLI)
- Skill files → `.agents/skills/` (picked up by Copilot CLI, Claude Code, and OpenCode)

---

## The Agents

| Agent | Alias | Specialty | Persona |
|-------|-------|-----------|---------|
| Martin Fowler | `@fowler` | Design patterns, refactoring, enterprise architecture | Precise, pattern-driven, catalog-oriented |
| Kent Beck | `@beck` | TDD, XP, simplicity | Direct, test-first, simplicity evangelist |
| Robert C. Martin | `@uncle-bob` | Clean Code, SOLID, OOP | Didactic, principled, rule-driven |
| Eric Evans | `@evans` | Domain-Driven Design, ubiquitous language | Strategic, domain-fluent, model-focused |
| Linus Torvalds | `@linus` | Performance, systems, code review | Blunt, performance-obsessed, no-nonsense |
| The Immortals | `@the-immortals` | Orchestrator — routes to Solo / Duo / Full Council | Routes based on problem complexity |

---

## Section 1: GitHub Copilot CLI (native)

GitHub Copilot CLI natively discovers agent files in `.github/agents/`. Any file matching `*.agent.md` in that directory is automatically available as a named agent. Skills in `.agents/skills/` are also picked up automatically.

### Using the install scripts

Run the Quick Install command above. That's it — agents and skills will be available in your next Copilot CLI session.

### Manual install

```bash
# Clone the repo (or download the files individually)
git clone https://github.com/yldgio/vibe-grimoire.git _grimoire

# Copy agent files to your project
cp _grimoire/.github/agents/fowler.agent.md   .github/agents/
cp _grimoire/.github/agents/beck.agent.md     .github/agents/
cp _grimoire/.github/agents/uncle-bob.agent.md .github/agents/
cp _grimoire/.github/agents/evans.agent.md    .github/agents/
cp _grimoire/.github/agents/linus.agent.md    .github/agents/
cp _grimoire/.github/agents/the-immortals.agent.md .github/agents/

# Copy skill files to your project
mkdir -p .agents/skills
cp -r _grimoire/skills/design-patterns      .agents/skills/
cp -r _grimoire/skills/refactoring          .agents/skills/
cp -r _grimoire/skills/performance-review   .agents/skills/
cp -r _grimoire/skills/clean-code           .agents/skills/
cp -r _grimoire/skills/domain-driven-design .agents/skills/
cp -r _grimoire/skills/the-immortals        .agents/skills/

# Clean up
rm -rf _grimoire
```

After copying, call an agent with `@fowler`, `@beck`, etc. in your Copilot CLI chat.

---

## Section 2: Claude Code

Claude Code does not have a native agents path (no `.agent.md` support). The workaround is to paste the persona directly into your `CLAUDE.md` as a named section — Claude Code reads `CLAUDE.md` as its system prompt context.

### Steps

1. Open (or create) `CLAUDE.md` in your project root.
2. Add a section for each agent you want, using the agent file content as a system-prompt snippet.

**Example — adding `@fowler`:**

```markdown
## @fowler — Martin Fowler

When invoked as @fowler, adopt the following persona:

### How you work
You are Martin Fowler. You think in patterns, catalog known solutions, and name things precisely.
Before writing code, identify which pattern applies. Reference your own catalog where relevant
(Refactoring, P of EAA, PoEAA, etc.). You prefer evolutionary design and incremental
improvement. You always ask: "Is there a simpler abstraction here?"

Your output style:
- Name the pattern before showing the code
- Show before/after when refactoring
- Call out code smells by name
- Prefer small, composable objects over large classes
```

Repeat for each agent, copying the `## How you work` block from the corresponding `.agent.md` file.

### Skills in Claude Code

Skills work normally — Claude Code reads `.agents/skills/`. Install them with the Quick Install script or copy manually (see Section 4).

---

## Section 3: OpenCode

OpenCode does not support `.agent.md` files, but it does read skills from `.agents/skills/`. The `the-immortals` skill provides the full routing logic and acts as the entry point for the council.

### Activating the council

Tell OpenCode:

```
Use the the-immortals skill
```

OpenCode will load the skill's `SKILL.md` and route your request to the right expert(s) based on problem complexity.

### Using individual skills directly

Each specialist skill also works standalone:

```
Use the design-patterns skill      # @fowler territory
Use the performance-review skill   # @linus territory
Use the clean-code skill           # @uncle-bob territory
Use the domain-driven-design skill # @evans territory
Use the refactoring skill          # cross-cutting
```

Install the skills with the Quick Install script or copy the skill directories to `.agents/skills/` manually (see Section 4).

---

## Section 4: Manual Install (any runtime)

Download individual files directly from GitHub if you prefer not to use the install scripts.

### Raw file URLs

**Agent files** (install to `.github/agents/`):

```
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/fowler.agent.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/beck.agent.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/uncle-bob.agent.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/evans.agent.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/linus.agent.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/.github/agents/the-immortals.agent.md
```

**Skill files** (install to `.agents/skills/<name>/SKILL.md`):

```
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/design-patterns/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/clean-code/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/refactoring/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/domain-driven-design/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/performance-review/SKILL.md
https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/skills/the-immortals/SKILL.md
```

### Target paths

| File | Install path |
|------|-------------|
| `fowler.agent.md` | `.github/agents/fowler.agent.md` |
| `beck.agent.md` | `.github/agents/beck.agent.md` |
| `uncle-bob.agent.md` | `.github/agents/uncle-bob.agent.md` |
| `evans.agent.md` | `.github/agents/evans.agent.md` |
| `linus.agent.md` | `.github/agents/linus.agent.md` |
| `the-immortals.agent.md` | `.github/agents/the-immortals.agent.md` |
| `design-patterns/SKILL.md` | `.agents/skills/design-patterns/SKILL.md` |
| `clean-code/SKILL.md` | `.agents/skills/clean-code/SKILL.md` |
| `refactoring/SKILL.md` | `.agents/skills/refactoring/SKILL.md` |
| `domain-driven-design/SKILL.md` | `.agents/skills/domain-driven-design/SKILL.md` |
| `performance-review/SKILL.md` | `.agents/skills/performance-review/SKILL.md` |
| `the-immortals/SKILL.md` | `.agents/skills/the-immortals/SKILL.md` |

### Download commands (curl)

```bash
# Create target directories
mkdir -p .github/agents \
  .agents/skills/design-patterns .agents/skills/clean-code \
  .agents/skills/refactoring .agents/skills/domain-driven-design \
  .agents/skills/performance-review .agents/skills/the-immortals

BASE=https://raw.githubusercontent.com/yldgio/vibe-grimoire/main

# Agents
curl -fsSL $BASE/.github/agents/fowler.agent.md         -o .github/agents/fowler.agent.md
curl -fsSL $BASE/.github/agents/beck.agent.md           -o .github/agents/beck.agent.md
curl -fsSL $BASE/.github/agents/uncle-bob.agent.md      -o .github/agents/uncle-bob.agent.md
curl -fsSL $BASE/.github/agents/evans.agent.md          -o .github/agents/evans.agent.md
curl -fsSL $BASE/.github/agents/linus.agent.md          -o .github/agents/linus.agent.md
curl -fsSL $BASE/.github/agents/the-immortals.agent.md  -o .github/agents/the-immortals.agent.md

# Skills
curl -fsSL $BASE/skills/design-patterns/SKILL.md        -o .agents/skills/design-patterns/SKILL.md
curl -fsSL $BASE/skills/clean-code/SKILL.md             -o .agents/skills/clean-code/SKILL.md
curl -fsSL $BASE/skills/refactoring/SKILL.md            -o .agents/skills/refactoring/SKILL.md
curl -fsSL $BASE/skills/domain-driven-design/SKILL.md   -o .agents/skills/domain-driven-design/SKILL.md
curl -fsSL $BASE/skills/performance-review/SKILL.md     -o .agents/skills/performance-review/SKILL.md
curl -fsSL $BASE/skills/the-immortals/SKILL.md          -o .agents/skills/the-immortals/SKILL.md
```

---

## See also

- [Main README](../README.md) — overview of the full grimoire
- [The Immortals design doc](../the-immortals-design.md) — philosophy and routing logic
- [Issues / PRs](https://github.com/yldgio/vibe-grimoire/issues) — bug reports and contributions welcome
