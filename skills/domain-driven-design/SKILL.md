---
name: domain-driven-design
description: >-
  Apply Domain-Driven Design principles: model the core domain, define
  bounded contexts, build context maps, design aggregates, identify domain
  events, and surface ubiquitous language. Use this skill early — a bad
  domain model compounds over time. Triggers: when teams argue about where
  logic should live, when the same word means different things to different
  teams, when a service is growing out of control, when someone says "our
  model doesn't match how the business thinks", when preparing a new
  microservice boundary, when the user says "the model feels wrong", "our
  domain is getting complicated", "we have inconsistent naming across teams",
  "where should this logic live?", "what's the aggregate root here?",
  "are these the same bounded context?", "strategic design", "tactical DDD",
  "what's the core domain?", "this looks like an anti-corruption layer",
  mentions "DDD", "Evans", "Blue Book", "domain events", "CQRS",
  "event sourcing" (strategic layer), or asks how to structure a complex
  multi-team system. Also triggers for: "ubiquitous language", "bounded
  context", "aggregate", "value object", "domain service", "context map".
---

# Domain-Driven Design

Model complex domains through deep collaboration with domain experts, making the model the center of the design — not the database, not the framework, not the API surface.

> *"The heart of software is its ability to solve domain-related problems for its users."* — Eric Evans

**Skill workflow** — DDD pairs naturally with language and architecture:
[`domain-language`](#) *(formalize the ubiquitous language first)* → **`domain-driven-design`** *(model the domain)* → [`adr`](#) *(record bounded context decisions)*

---

## Philosophy

Software complexity has two kinds of roots: **essential complexity** (the domain is genuinely hard) and **accidental complexity** (we made poor decisions). DDD addresses essential complexity by making the domain model the primary artifact of design.

The key insight: the model should reflect how domain experts think and speak. If your code uses different words than your domain experts, there's a translation tax on every feature. That tax compounds.

---

## Strategic Design

Strategic design answers: *where should we invest?* and *what are the natural boundaries?*

### Core Domain, Supporting Domains, Generic Domains

Before modeling, identify what actually matters:

| Domain type | Definition | Investment level |
|-------------|-----------|-----------------|
| **Core Domain** | Where your business differentiates. The reason competitors can't copy you. | Maximum — this is your competitive moat |
| **Supporting Domain** | Necessary for the business but not differentiating. | Moderate — build or buy strategically |
| **Generic Domain** | Commodity functionality any business needs. | Minimal — buy or use open source |

**Exercise:** Ask "if we outsourced this capability tomorrow, would we lose our competitive advantage?" Core domains answer yes.

### Bounded Contexts

A **Bounded Context** is the boundary within which a particular domain model applies consistently. The same word can mean different things in different bounded contexts — and that's fine, as long as the boundaries are explicit.

**Finding bounded contexts:**
- Where do the same words mean different things to different teams or departments?
- Where would merging models create more confusion than value?
- Where does a team own and evolve a model independently?

**Example:** "Order" in a Sales context means a customer's intent to purchase. "Order" in a Fulfillment context means a physical shipment instruction. These are different models that happen to share a name — they belong in separate bounded contexts.

> **Why separate contexts matter:** forcing a single Order model to serve both Sales and Fulfillment creates a model that is correct for neither. Every new feature becomes a negotiation between competing invariants — Sales wants promotions and pricing logic, Fulfillment wants shipment states and picking instructions. Separate the contexts and each model can evolve independently.

### Context Maps

A **Context Map** documents the relationships between bounded contexts. Name the integration pattern explicitly:

| Pattern | When to use |
|---------|------------|
| **Partnership** | Two teams co-evolve their contexts together; both adjust for the other |
| **Shared Kernel** | Two contexts share a small, explicitly defined subset of the model. High coordination cost — use sparingly |
| **Customer-Supplier** | Upstream (supplier) provides; downstream (customer) consumes. Supplier should accommodate customer needs |
| **Conformist** | Downstream adopts upstream model as-is. No translation. Chosen when the upstream model is good enough and translation cost is too high |
| **Anti-Corruption Layer (ACL)** | Downstream builds a translation layer to protect its model from upstream concepts. Use when upstream model is poor or foreign |
| **Open Host Service** | Upstream publishes a protocol (API, event schema) designed for external consumers. Multiple downstreams can integrate |
| **Published Language** | A well-documented, shared language (JSON schema, Protobuf, OpenAPI) used across context boundaries |

---

## Tactical Design

Tactical design answers: *how do we model within a bounded context?*

### Entities

An **Entity** is an object defined by its identity — not its attributes. Two entities with the same attributes are still distinct if their identities differ.

- Has a unique identity that persists through state changes
- Identity is meaningful to the domain (not just a database key)
- Examples: `Customer`, `Order`, `Employee`, `Account`

### Value Objects

A **Value Object** is defined entirely by its attributes. Two value objects with the same attributes are interchangeable. Value Objects should be **immutable**.

- No identity — equality is structural
- Immutable — operations return new instances. *Why: mutable value objects create aliasing bugs where two parts of the code hold a reference to the same instance and one silently mutates it; these are extremely hard to debug.*
- Examples: `Money`, `DateRange`, `Address`, `Color`, `Temperature`
- Most things that feel like Entities are actually Value Objects. If you don't need to track *which one* it is, it's a Value Object.

### Aggregates

An **Aggregate** is a cluster of Entities and Value Objects that form a consistency boundary. The **Aggregate Root** is the only object that external code can hold a reference to.

**Design rules:**
1. Enforce all invariants within the aggregate boundary (transactional consistency)
2. Reference other aggregates by identity only (no direct object references)
3. Keep aggregates small — one Aggregate Root, minimal associated objects
4. One transaction = one aggregate — if you're modifying two aggregates in one transaction, reconsider the model. *Why: this constraint forces you to distinguish what must be consistent right now from what can be eventually consistent. Most coordination requirements dissolve when you think carefully about invariants — what remains reveals real concurrency boundaries.*

**Finding aggregate boundaries:** Ask what invariant you're protecting. The aggregate exists to enforce that invariant atomically. If two objects don't need to be consistent *right now*, they're in different aggregates.

### Domain Events

A **Domain Event** is something that happened in the domain that domain experts care about. Events are first-class citizens in the model.

- Named in past tense: `OrderPlaced`, `PaymentDeclined`, `InventoryReserved`, `CustomerRegistered`
- If a domain expert would say "that happened and it matters", it's a Domain Event
- Events decouple bounded contexts: instead of context A calling context B, context A emits an event and context B reacts
- Events enable event sourcing: the state of an aggregate is the sum of its events

### Domain Services

A **Domain Service** handles domain logic that doesn't naturally belong to any Entity or Value Object.

- Stateless
- Named for a domain activity: `MoneyTransferService`, `ShippingCostCalculator`
- Only create a service when the operation involves multiple aggregates or doesn't belong to any single entity
- If you find yourself creating many services, the model may have lost its objects — check whether logic belongs on Entities or Value Objects instead

### Repositories

A **Repository** provides collection-like access to aggregates, abstracting persistence.

- One repository per aggregate root (not per entity)
- Interface defined in the domain layer; implementation in infrastructure
- Methods should speak the domain language: `find_all_overdue_orders()` not `select_where_status_eq("late")`. *Why: the repository is part of the domain model. SQL-leaking method names are an ACL violation inside your own codebase — they let infrastructure concepts bleed into the place business concepts belong.*
- Never return lazy-loaded objects that bypass the aggregate boundary

### Specifications

A **Specification** encapsulates a business rule as a predicate object. Use when selection or filtering logic is complex enough to deserve a name and is reused across repositories, domain services, or application code.

- Composable with `and`, `or`, `not` — eliminates `if`-chain sprawl without pushing logic into repositories
- Testable in isolation — each rule can be unit-tested independently
- Named for the business concept: `PremiumCustomerSpec`, `OverdueOrderSpec`, `EligibleBorrowerSpec`

```python
spec = CreditScoreSpec(min_score=700).and_(NoActiveLoanSpec()).and_(AffordabilitySpec(multiplier=24))
eligible_borrowers = borrower_repo.find_all_satisfying(spec)
```

When to use: whenever filtering logic is reused across contexts, or when an eligibility rule has a business name that domain experts use.

---

## Process

### 1. Identify the core domain

Before modeling, answer: what is this software's *reason to exist*? What problem does it solve that no commodity solution handles? That is the Core Domain. Everything else is supporting or generic.

### 2. Discover the ubiquitous language

Use the `domain-language` skill to extract and formalize the terminology that domain experts use. This language must be reflected in the code — class names, method names, variable names.

Ask: *"What do you call this? What happens when X? What does it mean when Y fails? Who is responsible for Z?"*

### 3. Find bounded context boundaries

Walk through scenarios with domain experts. Note where the same word means different things. Note where teams have different mental models of "the same" thing. Draw the boundaries there.

### 4. Draw the context map

For each pair of bounded contexts that interact, name the integration pattern explicitly. Record decisions in `adr`.

### 5. Model aggregates within each context

For each bounded context:
- Identify the Entities (things with identity)
- Identify the Value Objects (things defined by value)
- Find the invariants that must be enforced together → those define aggregate boundaries
- Identify Domain Events → what does the domain emit when something happens?

### 6. Validate the model

Test the model against edge cases and new scenarios with domain experts. A good model makes new scenarios easy to express. A poor model requires contortions.

---

## Anti-patterns

- **Anemic Domain Model** — objects that only hold data; all behavior in services. This is procedural programming in OOP clothing. Move behavior onto the objects that own the data.
- **God Aggregate** — one huge aggregate that owns everything for consistency. This creates contention and coupling. Decompose by finding the true invariant boundaries.
- **Leaking bounded context** — using another context's model directly instead of an ACL. Creates invisible coupling between contexts.
- **CRUD thinking** — modeling the system as a set of database tables with Create/Read/Update/Delete operations, ignoring domain behavior. The domain has events, decisions, and invariants — model those.
- **Premature optimization with CQRS/Event Sourcing** — these are powerful patterns, but add significant complexity. Apply only when the domain genuinely needs them, not as a default.

---

## Scope

This skill handles: strategic design (core domain, bounded contexts, context maps), tactical design (aggregates, entities, value objects, domain events, repositories, domain services).

This skill does **not** handle: implementation of specific patterns (use `design-patterns`), formalizing the glossary as a document (use `domain-language`), recording context map decisions (use `adr`).

When done, return control to the user.
