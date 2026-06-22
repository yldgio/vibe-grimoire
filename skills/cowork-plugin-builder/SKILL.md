---
name: cowork-plugin-builder
description: |
  Interview the user step-by-step to gather every detail needed to build a Microsoft 365 Copilot Cowork plugin package (manifest.json + skills + optional MCP connectors), then produce a complete, self-contained build prompt the user can review or hand off for execution.
  Use when the user asks to "create a cowork plugin", "build a copilot plugin", "make a M365 copilot agent package", "package my skills as a plugin", "create a copilot agent with MCP", "build a plugin for copilot cowork", or "wizard me through a cowork plugin".
  Do NOT use for: creating a single personal skill (use the `skills` skill instead), installing an existing plugin, troubleshooting plugin uploads that already exist, or general M365 admin questions.
license: MIT
---

# Cowork Plugin Builder

## What This Skill Does

Guides the user through a relentless, wizard-style interview — one question at a time — to capture every detail needed to construct a Microsoft 365 Copilot Cowork plugin package. At the end, produces a fully-specified build prompt (matching the canonical schema and packaging rules) that the user can either review/copy or hand back to the assistant to execute.

## When to Use

- "Help me build a Copilot Cowork plugin"
- "Create a M365 agent package with skills and an MCP server"
- "Wizard me through making a plugin"
- "Turn these skills into an uploadable plugin"
- "Package an MCP connector as a Cowork plugin"

## When NOT to Use

- Creating a single personal skill that lives in OneDrive → use the `skills` skill
- The user just wants to install or upload an existing `.zip` → answer directly
- General questions about what Copilot Cowork is → answer directly
- Editing a plugin manifest the user has already drafted → edit it directly without the interview

## Workflow

### Phase 1: Set Expectations

Before asking anything, tell the user:

> "I'll walk you through building a Copilot Cowork plugin one question at a time. I'll ask about the plugin's identity, each skill it should contain, and any MCP connectors. At the end I'll produce a complete build prompt you can review — and if you like it, I can build the package right away. Ready?"

Wait for confirmation, then proceed.

### Phase 2: Interview — One Question at a Time

**CRITICAL: Ask ONE question per turn.** Never batch questions. Use `AskUserQuestion` with concrete option choices whenever a finite set fits; otherwise ask in plain prose. After each answer, record it in a running state summary (kept in your working memory, not shown to the user).

Ask in this order. Skip a section only if the user has already volunteered the answer earlier in the conversation.

#### Section A — Plugin Identity (5 questions)

1. **Plugin short name** — "What's the short display name? (max ~30 chars, e.g. 'Financial Research')"
2. **Plugin full name** — "And the full name? (e.g. 'Microsoft Financial Research Tools')"
3. **Short description** — "Give me a one-sentence description (under 80 chars) that shows in the agent list."
4. **Full description** — "Now a 2-4 sentence description for the agent details page."
5. **Developer info** — "Developer name, website URL, privacy URL, terms-of-use URL? (any defaults you want me to use for missing ones?)"

#### Section B — Branding (2 questions)

6. **Accent color** — "Hex accent color for the agent? (default `#0078D4` Microsoft blue)"
7. **Icon concept** — "What simple glyph should the icons show? (e.g. 'chart', 'document', 'magnifier' — I'll generate 192×192 color and 32×32 outline PNGs)"

#### Section C — Language & Localization (1 question)

8. **Default language and additional locales** — `AskUserQuestion` (multiSelect):
   - Default language: en-US (US English), en-GB (UK English), it-IT (Italian), fr-FR (French), de-DE (German), es-ES (Spanish), ja-JP (Japanese), pt-BR (Portuguese), zh-CN (Simplified Chinese), Other
   - Additional locales: same list, allow multiple selections, or "None"

   The default language drives the `defaultLanguageTag` field in the manifest. Each additional locale gets a `localizationInfo.additionalLanguages[]` entry pointing at a `localization/<tag>.json` resource file the build prompt will scaffold.

#### Section D — Skills Inventory (loop)

9. **How many skills?** — "How many skills will this plugin contain?"

Then for **each** skill, ask in sequence (one question per turn):

   a. **Skill folder name** — "Skill #N — kebab-case folder name? (e.g. 'company-snapshot')"
   b. **Display name** — "Display name shown in the UI?"
   c. **Description (2-4 sentences)** — "Short description of what this skill does."
   d. **Trigger phrases** — "Give me 3 trigger phrases a user would say to invoke it."
   e. **Category** — `AskUserQuestion` with options: productivity, communication, analysis, writing, research, finance, automation, custom
   f. **Fluent UI icon** — "PascalCase Fluent icon name? (e.g. `BuildingBank`, `ChartMultiple`, `ShieldError`)"
   g. **Workflow steps** — "Briefly: what are the steps the skill performs? (one line per step is fine)"
   h. **Output format** — "What does the skill produce? (email, report, summary, chart, etc.)"
   i. **MCP tools used** — "Which MCP tools does this skill call? (list tool names, or 'none' if pure prose-driven)"

#### Section E — MCP Connectors (loop)

10. **Any MCP connectors?** — `AskUserQuestion`: Yes / No
11. If yes: **How many?**

For each connector:
   a. **Connector id** — "Short id (lowercase, e.g. `secedgar`)?"
   b. **Display name** — "Display name?"
   c. **Description** — "What public data or tools does it expose?"
   d. **MCP server URL** — "Full URL of the remote MCP endpoint (e.g. `https://example.com/mcp`)?"
   e. **Authorization** — `AskUserQuestion`: None (public) / OAuth / API key / Other
   f. **Valid domain** — auto-extract hostname from URL, confirm with user

#### Section F — Wrap-up (2 questions)

12. **Output paths** — "Default output paths OK? `output/<package-name>/` and `output/<package-name>.zip` — or override?"
13. **Build now or just the prompt?** — `AskUserQuestion`: "Generate the build prompt only" / "Generate the prompt AND build the package now"

### Phase 3: Synthesize the Build Prompt

After the interview, write a markdown file at `output/<package-name>-build-prompt.md` containing a complete, self-contained build prompt that follows the canonical structure in [references/build-prompt-template.md](references/build-prompt-template.md). Substitute every `{{placeholder}}` in the template with the collected answers. The output must include:

1. **Goal** — one paragraph stating what to build
2. **Output Path** — package folder + final ZIP path
3. **Package Structure** — tree showing every file (including any `localization/<tag>.json` files)
4. **manifest.json (CANONICAL SHAPE)** — full JSON with the user's collected values, including `defaultLanguageTag` and `localizationInfo`
5. **Localization files** — one JSON file per additional locale, with translated `name.short`, `name.full`, `description.short`, `description.full`
6. **Schema Rules (CRITICAL)** — encoded gotchas:
   - `agentSkills` and `agentConnectors` MUST be top-level (not under `copilotAgents`)
   - `manifestVersion` MUST be `"devPreview"`
   - `packageName` required (reverse-DNS)
   - `$schema` must be vDevPreview Teams URL
   - Fresh GUID v4 for `id`
   - `validDomains` must include MCP hostname
   - `defaultLanguageTag` MUST be a valid BCP-47 tag; locale files must match
7. **SKILL.md Frontmatter spec** — with `cowork.category` and `cowork.icon` nested under `metadata:`
8. **The N Skills** — one block per skill with folder, icon, triggers, MCP tools
9. **Icons** — 192×192 color PNG (#accent background, white glyph) + 32×32 outline PNG (transparent, white stroke); generate with Pillow
10. **Packaging** — Python `zipfile` snippet (manifest.json must be at ZIP root)
11. **Validation Checklist** — every gotcha as a checkbox
12. **Upload Path** — M365 Admin Center → Copilot → Agents → Upload agent. NOT Teams admin center.
13. **Done When** — explicit completion criteria

### Phase 4: Present and Offer to Execute

Show the user:
- The path to the generated build prompt (`output/<package-name>-build-prompt.md`)
- A short summary: N skills, M MCP connectors, default language, K additional locales, output ZIP path
- The choice from Section F.13: if they said "build now", invoke the build steps in a fresh task; if "prompt only", stop and tell them they can paste the prompt to any session (including a fresh one) to execute it.

If building now, follow every step in the generated prompt verbatim and verify against the embedded checklist before declaring done.

## Output Format

The primary deliverable is `output/<package-name>-build-prompt.md` — a single self-contained markdown file. If the user opted to build immediately, also produce `output/<package-name>/` and `output/<package-name>.zip` per the prompt.

## Guardrails

- **One question at a time.** Never batch. The interview style is the core value of this skill.
- **Never fabricate** developer URLs, MCP server URLs, or skill content. If the user doesn't know, mark with a clear `[TODO: ...]` placeholder in the build prompt.
- **Always include the schema gotchas** in the build prompt — they're encoded learnings from real upload failures.
- **GUID v4 for `id`** — generate fresh; never reuse an example GUID.
- **Validate every MCP URL hostname** lands in `validDomains`.
- **BCP-47 tags** — validate language tags (e.g. `en-US`, `it-IT`); reject invalid ones.
- **Confirm before building** — even if the user said "build now" upfront, show the assembled manifest snippet before zipping.

## Key Learnings Encoded

This skill bakes in the lessons from real plugin upload failures:

1. **Schema shape**: `agentSkills` / `agentConnectors` are top-level — nesting them under `copilotAgents` fails strict M365 validation.
2. **Two upload surfaces**: Teams admin center accepts the same package but silently drops unknown root properties. Always upload via M365 Admin Center → Copilot → Agents.
3. **Frontmatter nesting**: `cowork.category` and `cowork.icon` go UNDER `metadata:`, not at the top of the YAML.
4. **packageName required**: Reverse-DNS, e.g. `com.contoso.financial-research`.
5. **Rebuild the ZIP every time**: Stale ZIPs use old content.
6. **manifest.json at ZIP root**, not in a subfolder.
7. **Localization**: `defaultLanguageTag` plus `localizationInfo.additionalLanguages[]` pointing at `localization/<tag>.json` resource files.
