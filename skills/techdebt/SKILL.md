---
name: techdebt
description: >-
  Audit a codebase for technical debt: find and remove duplicated code, dead code,
  god objects, overly complex functions, inconsistent patterns, and other code smells.
  Use whenever the user wants to clean up code, reduce duplication, remove unused code,
  simplify complex logic, consolidate repeated patterns, improve code health, or mentions
  things like "this code is a mess", "we have too much copy-paste", "find all the
  duplicated logic", "do a code quality audit", "help me pay down tech debt", "clean up
  before the next sprint", "what needs refactoring", "unused code", "dead code",
  "we keep writing the same thing over and over", or asks to review code quality
  or maintainability. Also trigger for phrases like "DRY principle", "consolidate this",
  "our codebase is getting out of hand", or "I keep seeing this pattern everywhere".
---

# Tech Debt Auditor

Systematically find and remove duplicated code, dead code, and other forms of technical
debt — prioritized by impact, executed with the smallest safe changes possible.

**Skill workflow** — these skills chain naturally:
[`refactoring-plan`](#) *(plan the larger structural changes)* → **`techdebt`** *(execute the cleanup)* → [`tdd`](#) *(lock in behavior with tests before removing debt)*

---

## Debt Categories

Technical debt comes in several distinct flavors. Knowing which kind you're dealing with
shapes how you approach the fix.

| Category | What it looks like | Risk to fix |
|---|---|---|
| **Duplication** | Copy-paste blocks, near-identical functions, repeated logic with slight variations | Medium — consolidation can subtly break diverged behavior |
| **Dead code** | Unused exports, unreachable branches, commented-out blocks, always-on/off feature flags | Low — safe to delete if nothing calls it |
| **God objects** | Modules/classes that own too many responsibilities, files with 1000+ lines | High — requires careful extraction |
| **Deep nesting** | Arrow anti-pattern, callback hell, if/else pyramids deeper than 3 levels | Medium |
| **Magic values** | Literals (numbers, strings, URLs) scattered across the codebase instead of named constants | Low |
| **Inconsistent patterns** | Three different ways to handle errors, two different HTTP client wrappers, mixed async styles | Medium |
| **Overly complex functions** | Functions that do more than one thing, exceed ~40 lines, or have high cyclomatic complexity | Medium |

---

## Process

### 1. Define the scope

Before exploring, agree on scope with the user:

- **Full audit** — scan the entire codebase (good for smaller repos or "I don't know where to start")
- **Module audit** — focus on a specific directory or package
- **Targeted scan** — the user already suspects a specific debt type (e.g., "we have a lot of duplicate API helpers")

If they said something like "clean up this file" or "this module is messy", use that as the scope.
If scope is unclear, ask: *"Should I look at the whole repo or a specific area?"*

### 2. Explore the codebase

Use a subagent to scan for debt. The goal is to produce a raw list of findings — don't filter aggressively yet. Look for:

**Duplication signals**
- Functions with very similar names that do similar things
- Blocks of logic that appear in 2+ places with minor variation
- Utility functions re-implemented per module instead of shared
- Multiple files importing and re-exporting the same thing

**Dead code signals**
- Exported symbols that are never imported elsewhere
- Functions defined but never called within the scope
- Variables assigned but never read
- Commented-out code blocks (>5 lines)
- Conditional branches that are unreachable given the current config
- TODO/FIXME/HACK comments older than 30 days (if git blame is available)

**Complexity signals**
- Files exceeding ~300 lines
- Functions exceeding ~40 lines or with nesting depth > 3
- Files with a very high import count (god module indicator)

**Pattern inconsistency signals**
- Multiple competing implementations of the same utility (e.g., `formatDate`, `dateToString`, `toDateStr`)
- Mixed error handling styles in the same codebase
- Multiple HTTP/fetch wrappers

### 3. Build the debt inventory

Organize findings into a prioritized list. Use this priority order:

1. **High-value, low-risk** — dead code and magic values (safe deletes and extractions)
2. **High-value, medium-risk** — duplication consolidation and inconsistent patterns
3. **High-value, high-risk** — god object extraction (recommend `refactoring-plan` skill for these)

Present the inventory to the user grouped by category, with a severity indicator:
- 🔴 **Critical** — actively harmful (e.g., diverged duplicates that will cause bugs when one is updated but not the other)
- 🟡 **Moderate** — slows development, adds confusion
- 🟢 **Minor** — cosmetic or low-impact

Give the user a chance to confirm scope and reprioritize before starting any edits.

### 4. Fix debt, smallest-safe-change first

Work through the inventory one item at a time. For each item:

1. **Explain the debt**: why it's a problem, not just what it is
2. **Show the before**: the specific code causing the issue
3. **Propose the fix**: the minimal change that resolves it
4. **Get confirmation** before applying (unless the user has said "just do it")
5. **Apply the change**
6. **Verify**: run tests or at minimum confirm the change compiles/lints

For **duplication** specifically:
- Identify which version is the "canonical" one (most recently updated, most well-tested, or most correct)
- Check whether the copies have actually diverged — if they have, reconcile the differences before merging
- Replace all callsites with the canonical version before deleting the duplicates
- Don't silently change behavior: if copies differ, surface the difference to the user

For **dead code** specifically:
- Verify it is truly unreachable before deleting (check dynamic imports, reflection, string-based lookups)
- If in doubt, add a comment and let the user decide rather than deleting silently

For **god objects**:
- These are high-risk and usually deserve their own `refactoring-plan` session
- Flag them in the inventory but don't attempt extraction inline unless the user explicitly asks

### 5. Summarize what was done

After the cleanup session, produce a brief summary:

```
## Tech Debt Removed

**Deleted:** N dead code blocks
**Consolidated:** N duplicate implementations → 1 canonical
**Extracted:** N magic values → named constants
**Flagged for follow-up:** N god objects (recommend refactoring-plan)

Files changed: ...
Tests run: passing / N skipped
```

---

## Scope

This skill handles:
- Identifying and removing duplicated code
- Deleting dead code
- Extracting magic values to constants
- Consolidating inconsistent patterns
- Flagging god objects for follow-up

This skill does **not** handle:
- Large-scale architectural refactors (use `refactoring-plan`)
- Writing missing tests (use `tdd`)
- Performance optimization (unless caused directly by duplicated work)

When done, return control to the user.
