---
name: refactoring
description: >-
  Apply specific behavior-preserving refactoring moves to improve code structure
  without changing observable behavior. Use when the user wants to apply a
  specific refactoring, says "extract this method", "move this field", "replace
  this conditional", "inline this variable", "introduce a parameter object",
  "pull up this method", "push down this field", asks "how do I refactor this
  safely?", wants to apply a named refactoring from Fowler's catalog, needs
  to prepare code for a pattern, or says "I want to clean this up but I'm
  worried about breaking things". Distinct from refactoring-plan (which plans
  the overall strategy) — this skill executes specific moves.
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

The discipline is: **never mix refactoring with behavior change**. Refactor when green. Change behavior when refactored. Never both at once — that's how subtle bugs hide.

---

## The Safety Rule

Before any refactoring move:
1. **Tests must be passing.** If they're not, fix them first or write characterization tests to lock in current behavior.
2. **Make the move.** Apply the specific transformation — no logic changes, no "while I'm here" additions.
3. **Run tests.** They must still pass. If they don't, the move introduced a behavior change — revert immediately.
4. **Commit.** Each atomic move is a commit. Rollback should always be trivial.

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

```
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
