---
name: design-patterns
description: >-
  Identify, apply, and explain software design patterns — GoF creational,
  structural, and behavioral patterns plus enterprise application patterns.
  Use when the user asks which pattern fits their problem, wants to know if
  a pattern is being misapplied, needs to choose between patterns, says
  "what pattern should I use here", "is this a Strategy or a State?",
  "how do I implement an Observer in my language", "when should I use a Factory
  vs a Builder", "explain the Decorator pattern", "this code feels like it
  wants a pattern", mentions "design patterns", "GoF", "PEAA", or asks about
  any specific pattern by name. Also triggers when code shows a pattern
  being implemented incorrectly or unnecessarily.
---

# Design Patterns

Identify the right pattern for a problem, explain it precisely, and apply it with minimal disruption to the existing codebase. Patterns are vocabulary for communicating structure — not solutions to be force-fitted.

**Skill workflow** — patterns often follow from structural review:
[`refactoring`](#) *(prepare the ground for a pattern)* → **`design-patterns`** *(apply the pattern)* → [`adr`](#) *(record the architectural decision)*

---

## Philosophy

Patterns are named solutions to recurring design problems in a given context. Their value is not the solution itself — it's the name. When you say "Decorator", everyone on the team knows the structure, the intent, and the tradeoffs. Bad pattern usage happens in two ways:

- **Over-application** — using a pattern because it's a pattern, not because it solves a real problem. The Pattern Astronaut disease.
- **Misidentification** — implementing something that looks like a pattern but violates its invariants (e.g., a "Factory" that also manages object state — that's not a Factory).

> *"Each pattern describes a problem which occurs over and over again in our environment, and then describes the core of the solution to that problem."* — Christopher Alexander (precursor to GoF)

---

## Pattern Catalog

### Creational Patterns
| Pattern | Intent | Use when |
|---------|--------|---------|
| **Factory Method** | Define an interface for creating an object, let subclasses decide the type | You need to decouple object creation from the creator; creation logic may vary by subclass |
| **Abstract Factory** | Create families of related objects without specifying concrete classes | You need multiple related objects that must be consistent (e.g., UI theme components) |
| **Builder** | Separate construction of a complex object from its representation | Object requires many optional parameters; telescoping constructors are getting unwieldy |
| **Prototype** | Create objects by cloning existing instances | Creation cost is high; objects are configured at runtime and cloning is cheaper |
| **Singleton** | Ensure a class has only one instance with global access | Shared resource that must be coordinated (use sparingly — it's global state) |

### Structural Patterns
| Pattern | Intent | Use when |
|---------|--------|---------|
| **Adapter** | Convert an interface into another interface clients expect | Integrating incompatible interfaces; wrapping a legacy or third-party API |
| **Bridge** | Decouple abstraction from implementation so both can vary independently | Avoiding a class explosion when you have two dimensions of variation |
| **Composite** | Compose objects into tree structures to treat individual and group uniformly | Working with tree structures where leaves and composites share an interface |
| **Decorator** | Attach additional responsibilities to an object dynamically | Adding behavior without subclassing; behaviors should be combinable |
| **Facade** | Provide a simplified interface to a complex subsystem | Reducing coupling to a complex subsystem; simplifying a common usage path |
| **Flyweight** | Use shared state to efficiently support a large number of fine-grained objects | Large numbers of similar objects with shared state (e.g., characters in a text editor) |
| **Proxy** | Provide a surrogate that controls access to another object | Lazy initialization, access control, logging, caching around an object |

### Behavioral Patterns
| Pattern | Intent | Use when |
|---------|--------|---------|
| **Chain of Responsibility** | Pass a request along a chain of handlers until one handles it | Multiple objects may handle a request; handler is not known a priori |
| **Command** | Encapsulate a request as an object | Parameterize operations, support undo/redo, queue requests |
| **Iterator** | Provide sequential access to elements without exposing representation | Traversal of a collection without exposing its internals |
| **Mediator** | Define an object that encapsulates how objects interact | Many-to-many communication between objects; reducing direct dependencies |
| **Memento** | Capture and restore an object's internal state | Implementing undo; snapshotting state without violating encapsulation |
| **Observer** | Define a one-to-many dependency so observers are notified automatically | Event-driven systems; decoupling publishers from subscribers |
| **State** | Allow an object to alter its behavior when its internal state changes | Object behavior depends on state and must change at runtime |
| **Strategy** | Define a family of algorithms and make them interchangeable | Multiple algorithms for the same operation; selecting algorithm at runtime |
| **Template Method** | Define the skeleton of an algorithm, deferring steps to subclasses | Invariant parts of an algorithm in a base class; variant parts in subclasses |
| **Visitor** | Separate an algorithm from the object structure it operates on | Adding operations to objects without modifying them; double dispatch |

### Enterprise Application Patterns (Fowler's PEAA)
| Pattern | Intent |
|---------|--------|
| **Repository** | Mediate between domain and data mapping layers using a collection-like interface |
| **Unit of Work** | Maintain a list of objects affected by a business transaction |
| **Identity Map** | Ensure each object is loaded only once by keeping every loaded object in a map |
| **Data Mapper** | Move data between objects and a database while keeping them independent |
| **Active Record** | Object wraps a row in a database table and includes domain logic |
| **Service Layer** | Defines an application's boundary with a layer of services that establishes a set of available operations |
| **Domain Model** | An object model of the domain that incorporates behavior and data |
| **Transaction Script** | Organizes business logic by procedures where each procedure handles a single request from the presentation |

---

## Process

### 1. Identify the problem
Before reaching for a pattern, articulate the problem precisely:
- What is varying? (creation? behavior? structure? communication?)
- What is the coupling you're trying to break?
- What invariant are you trying to enforce?

A pattern applied without a clear problem statement is decoration, not design.

### 2. Pattern recognition
Look at the existing code structure:
- Are there `switch`/`if-else` chains on type? → *Strategy* or *State* may be appropriate
- Are objects being constructed with many optional parameters? → *Builder*
- Are you wrapping an external API to match your domain interface? → *Adapter* or *Facade*
- Are behaviors being stacked on objects at runtime? → *Decorator*
- Are you notifying multiple objects when something changes? → *Observer*

### 3. Evaluate fit
For each candidate pattern, ask:
- Does this solve the *specific* problem or just look like it does?
- What does this cost? (extra classes, indirection, learning curve)
- Is the problem likely to recur in a way that justifies the abstraction?
- Would a simpler approach (a function, a closure, a plain object) do the job?

### 4. Apply the pattern
- Make the smallest change that introduces the pattern
- Name things according to the pattern's vocabulary so intent is self-documenting
- Write tests before refactoring toward the pattern (see `tdd` skill)
- Apply the pattern through incremental refactoring moves (see `refactoring` skill)

### 5. Record the decision
If the pattern choice is non-obvious, use `adr` to record:
- What problem the pattern solves
- What alternatives were considered
- Why this pattern was chosen over simpler alternatives

---

## Anti-patterns

- **Pattern astronaut** — adding patterns because they're patterns, not because they solve problems. The cost of every abstraction must be justified by the problem it eliminates.
- **Wrong-dimension variation** — using Strategy when the variation is on state (that's State), using Decorator when you need composition across a hierarchy (that's Composite).
- **Singleton abuse** — Singleton is global mutable state with extra steps. Prefer dependency injection.
- **Factory everything** — if construction is simple and stable, a constructor is fine. Factories add indirection that must earn its keep.

---

## Scope

This skill handles: pattern identification, pattern selection, pattern application guidance, and recognizing misapplied patterns.

This skill does **not** handle: the mechanical refactoring steps to apply a pattern (use `refactoring`), recording the final decision (use `adr`), or domain modeling decisions (use `domain-driven-design`).

When done, return control to the user.
