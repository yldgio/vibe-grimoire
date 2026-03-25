---
name: kaizen
description: >
  Captures learning moments as short, permanent markdown notes in the project's
  kaizen/ directory, and registers them in AGENTS.md for progressive discovery.

  Invoke this skill automatically — without being asked — whenever ANY of these
  signals appear: the user corrects a mistake you just made ("no", "wrong", "not
  like that", "undo", "you missed", "that's not right"); the user redirects you
  after you went down the wrong path; you realize mid-task you made a significant
  error and had to backtrack; the user has to re-explain something you already
  got wrong once. This skill is compulsory — every learning must be captured.
  Do not skip it because the fix is already done. Do not wait to be asked.
  Invoke it as part of the same response where you acknowledge the correction.
---

# Kaizen

Every mistake or correction is signal. This skill captures it immediately — before the turn ends and the context is lost — as a short, permanent note in `kaizen/`.

The philosophy (from Japanese manufacturing): small, continuous improvements compound. A 5-10 line note written now can save hours later.

---

## When to invoke

Invoke when you detect any of these signals:

| Signal | Examples |
|--------|---------|
| **Explicit correction** | "no", "wrong", "not like that", "undo that", "that's incorrect" |
| **Path redirect** | User asks you to stop and restart differently after you've made progress |
| **Self-correction** | You catch an error mid-task and have to backtrack significantly |
| **Implicit correction** | User re-explains something you already got wrong; visible frustration |

Do **not** invoke for: requirement changes the user hadn't decided yet, minor typos, or one-off context-specific mistakes with no reusable lesson.

---

## How to write the note

### 1. Name the learning precisely

One sentence. Specific, not generic.
- ❌ "Be careful with git commands"
- ✅ "Always pass `--repo OWNER/REPO` to `gh issue create` when not inside the target repo"

### 2. Create the file

Path: `kaizen/YYYYMMDD-slug.md` where slug is 2–4 hyphenated words from the title.

```markdown
# [Short title — what was learned]

**Date**: YYYY-MM-DD | **Context**: [task / file / command where this happened]

## What happened
[1–2 sentences: the concrete mistake]

## Why it was wrong
[1–2 sentences: the underlying reason this matters]

## What to do instead
[2–3 sentences or bullet points: the correct approach going forward]
```

Keep it to 10–15 lines total. Scannable in 10 seconds is the goal.

### 3. Register in AGENTS.md

Add one line to the `## Kaizen Learnings` section at the bottom of `AGENTS.md`.
If the section doesn't exist yet, create it:

```markdown
## Kaizen Learnings

<!-- One line per entry: bold date + title, arrow, relative link -->
- **[YYYY-MM-DD] Short title** → [kaizen/YYYYMMDD-slug.md](kaizen/YYYYMMDD-slug.md)
```

For subsequent learnings, append a new line inside the existing section — never rewrite what's already there.

### 4. Then continue

After writing the note and updating AGENTS.md, proceed with fixing whatever went wrong. The note takes ~60 seconds to write.

---

## What makes a good note

- **Specific**: future you knows exactly what to do differently
- **Causal**: explains *why* the mistake happened, not just what happened
- **Actionable**: states the correct approach clearly enough to follow without re-reading the original conversation
