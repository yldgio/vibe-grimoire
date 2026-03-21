---
name: domain-language
description: >-
  Extract a DDD-style ubiquitous language glossary from the current conversation —
  flags ambiguities, resolves synonyms, and saves a canonical DOMAIN_LANGUAGE.md you
  can paste into your codebase or PRD. Use whenever the user wants to define domain
  terms, build a shared glossary, harden terminology, create a ubiquitous language,
  align on naming, or when the conversation reveals conflicting or inconsistent language.
  Also triggers on: "ubiquitous language", "bounded context", "domain model",
  "what should we call X", "are these the same thing", "we keep using these terms
  interchangeably", "dominio", "linguaggio di dominio", "DDD", or any discussion
  where the same concept keeps getting called different things.
---

# Domain Language

Extract and formalize domain terminology from the current conversation into a
consistent glossary, saved to `DOMAIN_LANGUAGE.md`.

**Related skills:** `create-prd` (write the PRD once terms are locked) · `pre-mortem`
(stress-test naming decisions before committing)

## Process

### 1. Determine starting point

Check whether `DOMAIN_LANGUAGE.md` already exists in the working directory.
- **File exists** → treat this as a **re-run** (jump to the Re-running section).
- **No file** → proceed with the steps below.

### 2. Gather source material

Scan the full conversation thread for domain-relevant nouns, verbs, and concepts.

If a codebase is in scope, also scan key files for implicit terminology: entity class
names, database column names, API route segments, enum values. Code often reveals
naming decisions that the conversation hasn't surfaced explicitly.

### 3. Identify terminology problems

Look for:
- **Ambiguity**: the same word used for different concepts
- **Synonyms**: different words used for the same concept
- **Vague terms**: overloaded generics ("item", "record", "thing") that deserve precise names
- **Implicit concepts**: things clearly present in the domain but never named

### 4. Propose the canonical glossary and confirm

Draft the glossary and present it to the user as a numbered list:
- Each canonical term with its proposed one-sentence definition
- Aliases to avoid
- Flagged ambiguities and your proposed resolution

Then ask: *"Does this look right? Any terms I missed, should rename, or define differently?"*

Iterate until the user approves — or, if they don't respond and the context makes intent
clear, proceed with your best judgment. The goal is to catch mistakes before they're
persisted to disk.

### 5. Write `DOMAIN_LANGUAGE.md`

Write the file using the format below. If fewer than three distinct domain terms emerged
from the conversation, write what you have and note in the file that the glossary is
incomplete — it will grow as the design conversation continues.

## Output Format

Write a `DOMAIN_LANGUAGE.md` file with this structure:

```md
# Domain Language

## Order lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Order** | A customer's request to purchase one or more items | Purchase, transaction |
| **Invoice** | A request for payment sent to a customer after delivery | Bill, payment request |

## People

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Customer** | A person or organization that places orders | Client, buyer, account |
| **User** | An authentication identity in the system | Login, account |

## Relationships

- An **Invoice** belongs to exactly one **Customer**
- An **Order** produces one or more **Invoices**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed. A single **Order** can produce multiple **Invoices** if items ship in separate **Shipments**."
> **Dev:** "So if a **Shipment** is cancelled before dispatch, no **Invoice** exists for it?"
> **Domain expert:** "Exactly. The **Invoice** lifecycle is tied to the **Fulfillment**, not the **Order**."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — these are distinct concepts: a **Customer** places orders, while a **User** is an authentication identity that may or may not represent a **Customer**.
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously in the conversation, call it out in the "Flagged ambiguities" section with a clear recommendation.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Only include domain terms.** Skip generic programming concepts (array, function, endpoint) unless they have domain-specific meaning.
- **Group terms into multiple tables** when natural clusters emerge (e.g. by subdomain, lifecycle, or actor). Each group gets its own heading and table. If all terms belong to a single cohesive domain, one table is fine — don't force groupings.
- **Write an example dialogue.** A short conversation (3-5 exchanges) between a dev and a domain expert that demonstrates how the terms interact naturally. The dialogue should clarify boundaries between related concepts and show terms being used precisely.

## Re-running

When invoked again in the same conversation:

1. Read the existing `DOMAIN_LANGUAGE.md`
2. Incorporate any new terms from subsequent discussion
3. Update definitions if understanding has evolved
4. Mark changed entries with "(updated)" and new entries with "(new)"
5. Re-flag any new ambiguities
6. Rewrite the example dialogue to incorporate new terms

## Post-output instruction

After writing the file, state:

> I've written/updated `DOMAIN_LANGUAGE.md`. From this point forward I will use these terms consistently. If I drift from this language or you notice a term that should be added, let me know.