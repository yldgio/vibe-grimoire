# Type Standards Reference

Authoritative guidance for each primitive type used by the `data-normalization`
skill. Read this file in Step 2 when drafting the Canonical Data Model.

---

## Dates and times

### Recommended standard: ISO 8601 extended with explicit UTC offset or `Z` for UTC

**Format:** `YYYY-MM-DDTHH:mm:ss[.SSS]([±HH:MM]|Z)`
**Examples:** `2024-01-15T14:30:00+00:00`, `2024-01-15T14:30:00.000Z`

**Why:**
- Human-readable and machine-parseable without a format string
- Unambiguous ordering (lexicographic sort equals chronological sort for UTC)
- Universally supported by JSON parsers, databases, and APIs
- Explicit offset (or `Z` for UTC) eliminates the "whose local time?" ambiguity

**UTC vs. local time:**
Prefer UTC (`+00:00`) for storage and transmission. Render in local time only at
the presentation layer. If a source provides a local time with no offset, treat
it as a data quality issue and flag it explicitly in the mapping table.

**Date-only values:**
Use `YYYY-MM-DD` (e.g., `2024-01-15`). Never attach a time or timezone to a
date-only field — `2024-01-15T00:00:00Z` is a timestamp, not a date, and will
silently shift across timezone boundaries.

**Common source formats and how to handle them:**

| Source format | Example | Transformation | Risk |
|---|---|---|---|
| Unix timestamp (seconds) | `1705329000` | `new Date(v * 1000).toISOString()` | Assumes UTC; confirm with source |
| Unix timestamp (milliseconds) | `1705329000000` | `new Date(v).toISOString()` | Assumes UTC |
| ISO 8601 without offset | `2024-01-15T14:30:00` | Append `+00:00` only if UTC is confirmed | High — silently wrong if not UTC |
| MySQL DATETIME | `2024-01-15 14:30:00` | Replace space with `T`, append offset | Must know server timezone |
| Locale string | `15/01/2024` | Parse with explicit format string | Ambiguous — reject at boundary |
| RFC 2822 | `Mon, 15 Jan 2024 14:30:00 +0000` | `new Date(v).toISOString()` | Safe if offset is present |

---

## Strings

### Recommended standard: UTF-8, NFC normalization

**Encoding:** UTF-8 for all string fields.

**Unicode normalization form:** NFC (Canonical Decomposition followed by
Canonical Composition). NFC is the form produced by most browsers and mobile
keyboards. It ensures that visually identical strings compare as equal
(e.g., `é` as a single code point vs. `e` + combining acute accent).

**Practical rules:**
- Normalize at the ingestion boundary, not at query time
- Trim leading/trailing whitespace unless whitespace is semantically significant
- Document `maxLength` per field in the canonical model — "unbounded" is a
  decision, not a default
- Reject null bytes (`\u0000`) at the boundary; they cause silent truncation in
  PostgreSQL and some C libraries

**Case:**
- Do not canonicalize case for human-facing strings (names, descriptions)
- Do canonicalize case for codes and identifiers (see Enums and Identifiers)

---

## Decimals and monetary values

### Recommended standard: integer minor units or Decimal with explicit scale

**Never use IEEE 754 floating-point** (`float`, `double`) for monetary values.
`0.1 + 0.2 === 0.30000000000000004` in most languages. Financial rounding
errors accumulate silently.

**Option A — Integer minor units (preferred for money):**
Store amounts as integers in the smallest currency unit.

| Currency | Minor unit | Example: $12.34 |
|---|---|---|
| USD | cent (1/100) | `1234` |
| EUR | cent (1/100) | `1234` |
| JPY | yen (no minor unit) | `1234` |
| BHD | fils (1/1000) | `12340` |

Always store the currency code alongside the amount. Never infer currency from
context.

```json
{ "amount_minor_units": 1234, "currency": "USD" }
```

**Option B — Decimal string with explicit precision:**
When the domain requires variable precision (scientific data, exchange rates):

```json
{ "value": "12.3400", "scale": 4 }
```

The scale (number of decimal places) must travel with the value.

**Common source formats and how to handle them:**

| Source format | Example | Transformation | Risk |
|---|---|---|---|
| Float | `12.34` | `Math.round(v * 10**minorUnit)` (for USD/EUR, `minorUnit = 2` → `* 100`) | Rounding if source has >scale or >minorUnit dp |
| Locale string | `"1.234,56"` | Strip `.` as thousands sep, replace `,` with `.` | Locale must be known |
| String with currency symbol | `"$12.34"` | Strip symbol, parse, multiply by `10**minorUnit` (e.g., `* 100` for USD/EUR) | Symbol must match expected currency and minorUnit |
| Integer cents | `1234` | Identity | Confirm unit with source docs |

---

## Identifiers

### Recommended standard: UUID v4

**Format:** `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` (lowercase, hyphenated)
**Example:** `550e8400-e29b-41d4-a716-446655440000`

**Why UUID v4:**
- Globally unique without a central authority
- No sequential information leaked (unlike UUID v1 or auto-increment integers)
- Supported natively by PostgreSQL, MongoDB, and most ORMs

**Alternatives to document if chosen:**
- **ULID** — sortable, URL-safe, 128-bit. Good for time-ordered records.
- **NanoID** — shorter, URL-safe. Good for user-facing IDs (slugs).
- **Auto-increment integer** — simple, but leaks record count and requires
  coordination across shards.

Whatever scheme is chosen, document it in the canonical model and apply it
consistently. Mixing UUID and integer IDs across the same domain is a source
of future join bugs.

**Cross-system identifier mapping:**
When a source uses its own ID scheme (e.g., Stripe's `cus_xxx`), store both:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",   // canonical
  "stripe_customer_id": "cus_abc123"               // external reference
}
```

Never use the external ID as the primary key in your system.

---

## Enums

### Recommended standard: SCREAMING_SNAKE_CASE with alias mapping

**Canonical value:** `SCREAMING_SNAKE_CASE` string
**Example:** `PAYMENT_PENDING`, `ORDER_CANCELLED`

**Why:**
- Instantly distinguishable from human-readable strings
- Case-insensitive matching is unambiguous (there is no ambiguity about
  `payment_pending` vs `Payment_Pending`)
- Consistent with most HTTP API conventions for status codes

**Alias mapping:**
Sources often use different labels for the same concept. Define the mapping
explicitly in the canonical model:

| Canonical value | Accepted source aliases |
|---|---|
| `PAYMENT_PENDING` | `pending`, `PENDING`, `0`, `false` |
| `PAYMENT_COMPLETED` | `completed`, `COMPLETE`, `success`, `1`, `true` |
| `PAYMENT_FAILED` | `failed`, `FAIL`, `error`, `-1` |

Reject any value not in the alias list. Never silently default to an enum
value when the source sends an unrecognized string.

---

## Booleans

**Canonical representation:** JSON `true` / `false` literals.

**Reject at the boundary:**
- Numeric `1` / `0`
- Strings `"true"` / `"false"` / `"yes"` / `"no"` / `"on"` / `"off"`
- Any other truthy/falsy coercion

These representations appear frequently in legacy systems and SQL query results.
Map them explicitly to `true` / `false` in the adapter layer.

---

## Null vs. absent

Define the contract explicitly for the project. Common approaches:

| Convention | Rule |
|---|---|
| **Null means unknown** | A `null` field is present but its value is not known. An absent field means "not applicable to this record type." |
| **Null and absent are equivalent** | Simpler; treat missing fields as `null` everywhere. |
| **No nulls allowed** | Use Option/Maybe types; absence of a value is represented by omitting the field entirely. |

Document which convention the project uses. Mixed conventions across different
parts of the same API are a common source of client bugs.

---

## References

- ISO 8601: <https://www.iso.org/iso-8601-date-and-time-format.html>
- Unicode NFC: <https://unicode.org/reports/tr15/>
- IEEE 754 floating-point: <https://en.wikipedia.org/wiki/IEEE_754>
- ULID specification: <https://github.com/ulid/spec>
- RFC 4122 (UUID): <https://www.rfc-editor.org/rfc/rfc4122>
