---
name: clean-code
description: >-
  Audit code for cleanliness: naming, function size and shape, class
  responsibilities, SOLID violations, comment hygiene, and Law of Demeter
  violations. Trigger when the user wants a clean code review, a naming audit,
  wants to apply SOLID principles, asks "is this code clean?", "are these
  names good?", "this function feels too big", "does this class do too much?",
  "should I break this up?", "is this DRY?", "does this violate SRP?",
  mentions "clean code", "Uncle Bob", "SOLID", "single responsibility",
  "open-closed", "dependency inversion", "interface segregation", "Law of
  Demeter", "Tell Don't Ask", or asks for a professional code quality review.
  Also trigger for: "is this readable?", "rename this", "what should I call
  this?", "this name is confusing". Trigger when a user pastes code and asks
  for general feedback — even without mentioning "clean". Trigger when
  reviewing a PR, when naming feels off, when a class is growing too large.
  When in doubt, run a clean-code pass — it catches issues every other skill
  misses.
---

# Clean Code

Systematically audit code for naming honesty, function clarity, class cohesion, SOLID violations, and comment necessity. Code is read far more than it is written — clean code respects the reader.

**Skill workflow** — clean code and tests reinforce each other:
**`clean-code`** *(make it readable)* → [`tdd`](#) *(make it testable — same virtue)* → [`techdebt`](#) *(remove accumulated mess)*

---

## Philosophy

> *"Clean code reads like well-written prose."* — Robert C. Martin

Clean code is not about aesthetics. It's about reducing the cognitive load required to understand, change, and extend the code. Every act of obfuscation — a vague name, an oversized function, a class with mixed concerns — is a tax on every future reader.

The fundamental question for every code element: **does this tell the truth?**

- Does the function name tell you what it does — fully, honestly, without reading the body?
- Does the class name tell you its single responsibility?
- Does the variable name tell you what it represents?
- Is every comment an admission that the code itself failed to communicate?

---

## SOLID Principles

### S — Single Responsibility Principle
Give each class **one reason to change** — not "one job" in the vague technical sense, but one *business force* that can cause it to change. Frame responsibility as ownership: ask "which team or which business concern would request a change to this class?" If two different teams can each cause you to open it, it has two owners and two responsibilities. This framing binds SRP to organisational reality, not to arbitrary technical decomposition.

**Signals of violation:**
- Class name contains "And", "Or", "Manager", "Handler", "Helper", "Utility"
- Class imports both domain logic and infrastructure concerns
- Methods in the class have nothing to do with each other

### O — Open/Closed Principle
Classes should be **open for extension, closed for modification**. New behavior should be addable without changing existing code.

**Signals of violation:**
- `switch`/`if-else` chains on type that must be updated every time a new type is added
- Adding a new feature requires modifying multiple existing classes
- The extension point doesn't exist — you have to crack open the class every time

### L — Liskov Substitution Principle
Derived types must be **substitutable for their base types** without breaking callers. Inheritance should model *is-a*, not just code reuse.

**Signals of violation:**
- Subclass throws exceptions the base class doesn't throw
- Subclass overrides a method to do nothing (or throws `UnsupportedOperationException`)
- Callers must type-check before calling methods on a "base" type

### I — Interface Segregation Principle
**No client should depend on methods it doesn't use.** Fat interfaces create coupling to behavior clients don't need.

**Signals of violation:**
- Interface has many methods but most implementations only use a few
- Mock objects implementing an interface have many empty/throw implementations
- The interface name is vague ("IService", "IHelper") — probably too broad

### D — Dependency Inversion Principle
**High-level policy should not depend on low-level detail.** Both should depend on abstractions. Abstractions should not depend on details; details should depend on abstractions.

**Signals of violation:**
- Business logic directly instantiates infrastructure classes (`new PostgresRepository()` in a service)
- High-level modules import from low-level modules
- Testing requires real databases, real file systems, real network connections

---

## Naming Audit

Naming is the hardest thing in programming and the most impactful. Bad names are lies.

### Function naming
- **Verb + noun** for commands: `calculateTax()`, `sendConfirmationEmail()`, `validatePaymentMethod()`
- **Boolean-returning functions** should be predicates: `isValid()`, `hasPermission()`, `canCheckout()`
- **No and/or in names** — if the function name contains "and" or "or", it does two things
- **No vague verbs** — `process()`, `handle()`, `manage()`, `do()` are name failures. What specifically does it process?
- **Length ∝ scope** — a loop variable can be `i`; a function parameter needs a descriptive name; a class field needs a precise name

### Class naming
- **Noun or noun phrase** that names exactly one responsibility
- **Avoid**: Manager, Handler, Helper, Utility, Service (these are not responsibilities — they're evasions)
- **Concrete names** — `OrderRepository` not `DataService`; `PaymentCalculator` not `PaymentHelper`

### Variable naming
- **Reveal intent** — `daysSinceLastLogin` not `d`; `eligibleUsers` not `users2`
- **Avoid encodings** — Hungarian notation and type prefixes (`strName`, `iCount`) are noise
- **Avoid disinformation** — don't name a `List` `accountList` if it might become a `Set` or `Map`
- **Distinguish meaningfully** — `a1` and `a2` say nothing; if you have two, they have different roles, name them

---

## Function Shape Audit

### Size
- Functions longer than ~20 lines are almost certainly doing more than one thing
- Each step of a function should be at the same level of abstraction
- If a function needs comments to separate its sections, those sections are separate functions

### Abstraction levels
Never mix high-level intent with low-level detail in the same function. The reader's brain must context-switch between *what the function is doing* and *how it does it* simultaneously — two incompatible cognitive modes at once. Extract low-level blocks into named functions so the caller reads like a table of contents:
```
# Mixed levels — hard to follow
def process_order(order):
    items = [i for i in order.items if i.quantity > 0]  # low level
    if not items:
        raise ValueError("no items")                      # low level
    total = sum(i.price * i.quantity for i in items)     # low level
    send_confirmation_email(order.customer, total)        # high level
    update_inventory(items)                               # high level
```
Either all steps are at the same level, or each low-level block is extracted into a named function.

### Arguments
- 0 arguments: ideal
- 1 argument: fine
- 2 arguments: acceptable
- 3 arguments: consider a parameter object
- 4+ arguments: strong signal that a class or parameter object is needed

---

## Law of Demeter — Tell, Don't Ask

A method should only call methods on: itself, its direct fields, objects it creates, and parameters passed directly to it. Reaching through an object to call a method on one of *its* internals is a violation.

`a.getB().getC().doSomething()` is a Demeter violation: the caller is coupled to the internal structure of `a` — that it contains a `B`, and that `B` contains a `C`. When that structure changes, the caller breaks even though it never cared about `B` or `C`.

**Before (violation):**
```python
email = order.get_customer().get_contact_info().get_email()
tax   = order.get_customer().get_region().get_tax_rate()
```

**After (compliant):**
```python
email = order.get_customer_email()    # Order encapsulates the traversal
tax   = order.get_applicable_tax_rate()
```

Add the method to the object nearest the data and let the message travel internally. The caller tells the object what it needs; it does not ask for parts and assemble the answer itself.

**Signals of violation:**
- Method chains with three or more dots
- Code that navigates an object graph just to extract a leaf value
- Tests requiring deeply nested mock setups to satisfy internal traversal

---

## Comment Hygiene

Every comment is evidence the code failed to express its intent. Not because comments are inherently bad — but because each comment imposes a maintenance tax: when the code changes, the comment must change too, or it silently becomes a lie. Before writing a comment, try to eliminate the need for it: rename the function, extract a named variable, split the method. Comments should be rare and earned.

**Comments that fail:**
```python
# increment i
i += 1

# check if user is admin
if user.role == "admin":
```

**Comments that earn their place:**
- Legal/license headers
- Intent that cannot be expressed in code ("We tried approach X here — it doesn't work because of Y race condition")
- Warning about non-obvious consequences
- TODO with specific task and owner
- Explaining *why* an algorithm works (not what it does)

---

## Process

### 1. Scope the audit
Agree with the user: full codebase, specific module, specific file, or specific code block?

### 2. Naming pass
Read every function, class, and variable name. Ask for each:
- Does this tell the truth?
- Could it be more specific?
- Does it contain "and", "or", "helper", "manager", "handler", "utility"?

### 3. Function size and shape pass
For each function:
- Is it doing more than one thing?
- Are abstraction levels mixed?
- Are there more than 3 arguments?

### 4. SOLID pass
Check each class against SRP, OCP, LSP, ISP, DIP. List violations with the specific signal that triggered them.

### 5. Law of Demeter pass
Scan for method chains. Flag any chain that traverses more than one object boundary. Propose wrapper methods on the owning object.

### 6. Comment pass
Read every comment. Ask: does the code explain itself without this comment? If yes, delete it. If no, the name or structure failed — fix that instead where possible.

### 7. Propose changes
For each finding:
1. State what the issue is (naming failure, SRP violation, etc.)
2. Show the specific code
3. Propose the specific fix
4. Note the risk if behavior change is possible

---

## Scope

This skill handles: naming audits, SOLID analysis, function shape review, comment hygiene.

This skill does **not** handle: architectural pattern decisions (use `design-patterns`), large-scale refactoring planning (use `refactoring-plan`), tech debt inventory across a whole codebase (use `techdebt`).

When done, return control to the user.
