---
name: refactoring
description: >-
  Apply specific behavior-preserving refactoring moves to improve code structure
  without changing observable behavior. Trigger when: code has long methods
  (more than ~20 lines), a user says "this is getting complicated" or "how do
  I clean this up safely", someone is preparing to apply a design pattern,
  a method is doing more than one thing, you see Feature Envy or a conditional
  dispatching on type. Also triggers on: "extract this method", "move this
  field", "replace this conditional", "inline this variable", "introduce a
  parameter object", "pull up this method", "push down this field", "how do I
  refactor this safely?", or any named refactoring from Fowler's catalog. Trigger
  this skill before applying any design pattern — refactoring prepares the ground.
  Distinct from refactoring-plan (which plans the overall strategy) — this skill
  executes specific moves.
---

# Refactoring

Apply specific, named, behavior-preserving refactoring moves — one at a time, with tests passing before and after each move.

> *"Make each refactoring step as small as possible, so that you can always see the program working."* — Martin Fowler

**Skill workflow** — refactoring follows from audit and precedes patterns:
[`clean-code`](#) or [`techdebt`](#) *(identify what needs changing)* → **`refactoring`** *(apply the moves)* → [`design-patterns`](#) *(apply a pattern if one is now appropriate)*

> **Note:** This skill covers the *execution* of specific moves. For planning a larger structural change — choosing strategy, mapping blast radius, breaking into safe commits — use [`refactoring-plan`](#) instead.

---

## Philosophy

Refactoring is not rewriting. It is a sequence of small, mechanical, behavior-preserving transformations. Each step:
- Leaves the code working (tests pass)
- Is independently understandable
- Moves toward better structure

The discipline is: **never mix refactoring with behavior change**. When you mix the two, bugs hide in the transformation — you can't tell if a test failure is a refactoring bug or an intentional behavior change. Refactor when green. Change behavior when refactored. Never both at once.

---

## The Safety Rule

Before any refactoring move:
1. **Tests must be passing.** If they're not, fix them first or write characterization tests to lock in current behavior.
2. **Make the move.** Apply the specific transformation — no logic changes, no "while I'm here" additions.
3. **Run tests.** They must still pass. If they don't, the move introduced a behavior change — revert immediately.
4. **Commit.** Each atomic move is its own commit — so you can always `git bisect` to pinpoint exactly where behavior changed, and rollback is trivial and surgical.

---

## Refactoring Catalog

### Extract Method
**When:** A code fragment can be grouped together, and the grouping can be given a name that communicates intent.

```
# Before
def print_owing(self, amount):
    # print banner
    print("*" * 20)
    print("* Customer Owes *")
    print("*" * 20)
    print(f"name: {self.name}")
    print(f"amount: {amount}")

# After
def print_owing(self, amount):
    self._print_banner()
    self._print_details(amount)

def _print_banner(self):
    print("*" * 20)
    print("* Customer Owes *")
    print("*" * 20)

def _print_details(self, amount):
    print(f"name: {self.name}")
    print(f"amount: {amount}")
```

**Risk:** Low. Watch for: variables used in the extracted block that need to become parameters; return values when the block produces a result.

---

### Inline Method
**When:** A method's body is as clear as its name. The indirection adds no value.

```
# Before
def is_more_than_five_late_deliveries(self):
    return self.number_of_late_deliveries > 5

def get_rating(self):
    if self.is_more_than_five_late_deliveries():
        return 2
    return 1

# After
def get_rating(self):
    if self.number_of_late_deliveries > 5:
        return 2
    return 1
```

**Risk:** Low. Watch for: recursive methods; methods overridden in subclasses.

---

### Extract Variable
**When:** An expression is hard to understand. Give it a name.

```
# Before
if (platform.toUpperCase().indexOf("MAC") > -1) and
   (browser.toUpperCase().indexOf("IE") > -1) and
   wasInitialized() and resize > 0:

# After
is_mac_os = platform.toUpperCase().indexOf("MAC") > -1
is_ie = browser.toUpperCase().indexOf("IE") > -1
was_resized = resize > 0

if is_mac_os and is_ie and wasInitialized() and was_resized:
```

**Risk:** Low.

---

### Introduce Parameter Object
**When:** A group of parameters always travels together. Replace them with an object.

```
# Before
def amount_invoiced(start_date, end_date): ...
def amount_received(start_date, end_date): ...
def amount_overdue(start_date, end_date): ...

# After
class DateRange:
    def __init__(self, start, end): ...

def amount_invoiced(date_range): ...
def amount_received(date_range): ...
def amount_overdue(date_range): ...
```

**Risk:** Low → Medium. The new object may acquire behavior over time (good) but can also become a grab-bag (bad). Keep it focused.

---

### Move Method / Move Field
**When:** A method or field is used more by another class than the class it's in (Feature Envy smell).

Move it to the class that uses it most. Update all callers. Run tests.

**Risk:** Medium. Check: is this method called from many places? Is the move making the caller's interface messier?

---

### Replace Conditional with Polymorphism
**When:** You have a conditional that selects different behavior based on the type of an object. Replace the `switch`/`if-else` chain with polymorphism.

```
# Before
def get_speed(self):
    if self.type == EUROPEAN:
        return self.base_speed()
    elif self.type == AFRICAN:
        return self.base_speed() - self.load_factor * self.number_of_coconuts
    elif self.type == NORWEGIAN_BLUE:
        return 0 if self.is_nailed else self.base_speed(self.voltage)

# After — each bird type is its own class
class EuropeanSwallow:
    def get_speed(self): return self.base_speed()

class AfricanSwallow:
    def get_speed(self): return self.base_speed() - self.load_factor * self.number_of_coconuts

class NorwegianBlueParrot:
    def get_speed(self): return 0 if self.is_nailed else self.base_speed(self.voltage)
```

**Risk:** Medium. Only appropriate when the conditional is truly dispatching on type, not on data state (that's Strategy or State pattern territory).

---

### Replace Temp with Query
**When:** A temporary variable holds the result of an expression. Extract it into a method so it can be called from anywhere.

```
# Before
def get_total(self):
    base_price = self.quantity * self.item_price
    if base_price > 1000:
        return base_price * 0.95
    return base_price * 0.98

# After
def base_price(self):
    return self.quantity * self.item_price

def get_total(self):
    if self.base_price() > 1000:
        return self.base_price() * 0.95
    return self.base_price() * 0.98
```

**Risk:** Low. Watch for: expressions with side effects (don't extract those); performance-sensitive paths where recalculation is expensive.

---

### Pull Up Method / Push Down Method
**When:** Methods on subclasses that are identical → Pull Up to superclass.
**When:** Superclass behavior that only one subclass uses → Push Down to that subclass.

**Risk:** Medium. Verify the method's behavior is truly identical across subclasses before pulling up.

---

### Change Function Declaration (Rename / Add/Remove Parameter)
**When:** A function's name doesn't reveal its intent, or its parameter list can be simplified.

Apply mechanically: rename in the declaration, update all call sites, run tests.

**Risk:** Low → Medium depending on how many call sites exist and whether this is a public API.

---

### Decompose Conditional
**When:** A complex conditional (`if`/`else if`/`else`) is hard to follow. Extract each branch into a named method.

When you name a branch `is_not_summer()` or `winter_charge()`, the branch name communicates intent at a glance. The condition becomes self-documenting — readers understand the *why* without tracing the *how*.

```python
# Before
if date.before(SUMMER_START) or date.after(SUMMER_END):
    charge = quantity * winter_rate + winter_service_charge
else:
    charge = quantity * summer_rate

# After
if self.is_not_summer(date):
    charge = self.winter_charge(quantity)
else:
    charge = self.summer_charge(quantity)
```

**Risk:** Low.

---

### Consolidate Conditional Expression
**When:** Multiple conditions all lead to the same result. Combine them into one expression and extract it into a named method.

```python
# Before
def get_disability_amount(self):
    if self.seniority < 2:
        return 0
    if self.months_disabled > 12:
        return 0
    if self.is_part_time:
        return 0
    # ... calculate amount

# After
def get_disability_amount(self):
    if self.is_not_eligible_for_disability():
        return 0
    # ... calculate amount

def is_not_eligible_for_disability(self):
    return self.seniority < 2 or self.months_disabled > 12 or self.is_part_time
```

**Why:** Separate conditions returning the same value are really one check expressed redundantly. Combining them signals to readers that they form a unified intent. The extracted method name replaces a wall of logic with a single readable statement.

**Risk:** Low. Only consolidate conditions that are logically related and serve the same purpose.

---

### Separate Query from Modifier
**When:** A method both returns a value AND changes state. Split it into two: a pure query (returns a value, no side effects) and a command (changes state, returns nothing).

This is the **Command-Query Separation** principle (Bertrand Meyer): a method should either answer a question *or* perform an action — never both. Mixing the two forces callers to reason about hidden state mutations every time they read a value.

```python
# Before
def get_total_outstanding_and_set_ready_for_summary(self):
    result = sum(o.amount for o in self.orders)
    self.send_bill()
    return result

# After
def total_outstanding(self):   # query — pure, no side effects
    return sum(o.amount for o in self.orders)

def send_bill(self):           # command — side effect, returns nothing
    ...

# Caller:
total = account.total_outstanding()
account.send_bill()
```

**Risk:** Low → Medium. Update callers that previously got both effects in one call.

---

### Encapsulate Field
**When:** A class exposes a public field. Make it private and provide accessor methods.

```python
# Before
class Person:
    name = ""   # public

# After
class Person:
    def __init__(self):
        self._name = ""

    def get_name(self):
        return self._name

    def set_name(self, value):
        self._name = value
```

**Why:** A public field is a contract — every caller reads and writes it directly, making future changes (validation, caching, computed derivations) impossible without breaking all callers. Accessors give you an interception point. Start private; it's trivial to open up, but nearly impossible to lock down after the fact.

**Risk:** Low for the field itself. Medium if the field is referenced across many call sites — update all reads and writes.

---

## Process

### 1. Identify the move
Name the specific refactoring you're applying. "Extract Method", "Introduce Parameter Object", etc. If you can't name it, you don't know what you're doing yet.

### 2. Verify tests are green
Run the test suite. If tests are failing, that's a separate problem. Don't refactor on red.

### 3. Apply the move — and only the move
Make exactly the transformation described by the refactoring. No behavior changes. No "while I'm here" additions.

### 4. Run tests
Tests must still pass. If they don't, the move changed behavior — revert and re-examine.

### 5. Commit
Each atomic move is one commit. Message format: `refactor: extract method extractUserDetails from processUser`

### 6. Repeat
Refactoring is iterative. Each move reveals the next opportunity.

---

## Scope

This skill handles: specific named refactoring moves, step-by-step execution, keeping tests green throughout.

This skill does **not** handle: choosing the overall refactoring strategy (use `refactoring-plan`), identifying what needs refactoring (use `techdebt` or `clean-code`), applying design patterns as a destination (use `design-patterns`).

When done, return control to the user.
