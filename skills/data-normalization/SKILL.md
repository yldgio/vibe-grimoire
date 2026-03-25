---
name: data-normalization
description: >-
  Establish a Canonical Data Model for a project — define authoritative format
  rules for each primitive type (dates as ISO 8601 with explicit timezone,
  strings as UTF-8, decimals with explicit precision, identifiers, enums),
  map every data source to the canonical form with a field-by-field table,
  generate adapter / validator code, and record decisions in an ADR.
  Use whenever someone says "canonical data model", "data contracts",
  "normalize our types", "dates come in different formats from different APIs",
  "map this API response to our internal model", "how should we store decimals
  or money", "data format inconsistencies", "interoperability between services",
  "we need a common format", or when integrating multiple data sources
  (APIs, databases, files, queues) that use conflicting field formats.
  Also trigger proactively when you observe that a conversation involves
  two or more data sources with different primitive-type representations.
---

# Data Normalization

Define a shared, authoritative format for every primitive type in a project and
produce the artifacts that enforce it: a `CANONICAL_DATA_MODEL.md`, field
mapping tables per source, adapter / validator code, and an ADR.

**Related skills:** `domain-language` (align on naming before locking formats) ·
`adr` (record format decisions)

## Scope

This skill covers:

- Authoring or updating a `CANONICAL_DATA_MODEL.md` that defines the internal
  format for each primitive type used in the project
- Producing field-by-field mapping tables from each external source to the
  canonical model
- Generating adapter / validator code in the project's target language
- Filing an ADR that records why these formats were chosen and what was rejected

This skill stops at the data contract boundary. It does **not** design full
entity schemas, write business logic, perform database migrations, or
implement persistence layers.

## Step 1: Discover the data landscape

Ask the user the following before writing anything:

1. What data sources exist — external APIs, databases, message queues, files?
   For each, what format do they use for dates, amounts, identifiers, and strings?
2. What is the target language and framework for generated adapter / validator code?
3. Which type mismatches are causing the most pain right now?
4. Are there any existing schema conventions, style guides, or standards already
   adopted in the project (e.g., "we already use snake_case everywhere")?

If the user's answers are partial, make reasonable inferences and state them
explicitly so they can be corrected.

## Step 2: Draft the Canonical Data Model

Read `references/type-standards.md` for authoritative guidance on each type.

Propose a rule for every relevant primitive type. A minimal set covers:

| Type | Canonical rule |
|------|---------------|
| **Date / time** | ISO 8601 extended, explicit UTC offset — `2024-01-15T14:30:00+00:00` |
| **Date only** | ISO 8601 date — `2024-01-15` (no time, no zone) |
| **String** | UTF-8, NFC normalization; document max-length per field |
| **Decimal / money** | Explicit scale and precision; reject IEEE 754 floats for monetary values |
| **Identifier** | UUID v4 (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`) unless project uses a different scheme |
| **Enum** | `SCREAMING_SNAKE_CASE` as canonical; list allowed source aliases per value |
| **Boolean** | `true` / `false` literals; reject `1`/`0`, `"yes"`/`"no"` at the boundary |
| **Null vs. absent** | Define explicitly: is a missing field equivalent to `null`, or a distinct state? |

Show the draft to the user and ask for confirmation before writing the file.
Iterate until they approve, then save to `CANONICAL_DATA_MODEL.md` in the
project root (or a path the user specifies).

Use this template:

```markdown
# Canonical Data Model

> Last updated: YYYY-MM-DD

## Purpose

One-sentence statement of why this document exists and who must follow it.

## Type rules

| Type | Canonical format | Rationale | Rejected alternatives |
|------|-----------------|-----------|----------------------|
| Date / time | ISO 8601, explicit UTC offset | ... | Unix timestamps, locale strings |
| ... | ... | ... | ... |

## Per-field overrides

Document any fields that intentionally deviate from the type rules above,
with the reason.

| Field | Override | Reason |
|-------|---------|--------|
| `event.occurred_at` | Unix ms integer | Kafka schema compatibility |

## Versioning

State how breaking changes to this document are communicated
(e.g., semver in a header field, ADR per change).
```

## Step 3: Map external sources to canonical form

For each data source identified in Step 1, produce a mapping table:

```markdown
### Source: <name> (<protocol/format>)

| Source field | Source type | Canonical field | Canonical type | Transformation rule | Loss risk |
|---|---|---|---|---|---|
| `created_at` | Unix timestamp (s) | `created_at` | ISO 8601 UTC | `new Date(v * 1000).toISOString()` | none |
| `amount` | float | `amount_minor_units` | integer | `Math.round(v * 10 ** minorUnit)` — e.g. `* 100` for USD/EUR (2dp), `* 1` for JPY (0dp), `* 1000` for BHD (3dp) | rounding if source has more decimal places than `minorUnit` |
```

Flag every field where the transformation is lossy or ambiguous (e.g., a
source timestamp with no timezone information). These fields need explicit
decisions — note them as open questions if the user has not already resolved them.

## Step 4: Generate adapter / validator code

Using the mapping tables from Step 3, generate code that:

1. **Validates** inbound data against the canonical rules (rejects bad types,
   out-of-range values, or forbidden formats at the boundary)
2. **Transforms** source-format fields into canonical fields
3. **Raises typed errors** with the field name and the violation reason — never
   silently coerce

Ask the user where to save each adapter (e.g., `src/adapters/`, `lib/normalizers/`).
Generate one file per source to keep concerns separate.

Prefer using the project's existing validation library if one is present
(e.g., `zod`, `pydantic`, `joi`). Read the codebase briefly to check before
generating a custom solution.

## Step 5: Write the ADR

Invoke the `adr` skill to document the data contract decisions. The ADR should
cover at minimum:

- Why ISO 8601 with explicit timezone was chosen over Unix timestamps or local time
- Why floating-point was rejected for monetary values
- Any source-specific overrides and why they are exceptions rather than the rule
- A reference to `CANONICAL_DATA_MODEL.md`

## Done

The skill is complete when all of the following are true (or explicitly waived
by the user):

1. `CANONICAL_DATA_MODEL.md` is saved and approved
2. A mapping table exists for each data source named in Step 1
3. Adapter / validator files are written and saved at the agreed paths
4. An ADR is filed (or the user has opted out of the ADR step)

Print a one-line summary:

> Produced: `CANONICAL_DATA_MODEL.md`, adapters for [source list], ADR-NNNN.
