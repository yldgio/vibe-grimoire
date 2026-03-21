---
name: tdd
description: >-
  Test-driven development with red-green-refactor loop. Use when the user wants
  to build features or fix bugs using TDD, write tests for existing code, add
  tests to a module, make code more testable, says "write tests for this",
  "help me test this", "how do I test this", "my tests keep breaking when I
  refactor", "I don't know what to test", "should I write the test first",
  "make this testable", "how do I write good tests", mentions
  "red-green-refactor", wants integration tests, or asks for test-first
  development.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces **bad tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes — they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Reference Files

| File | When to read |
|------|-------------|
| [tests.md](tests.md) | Examples of good vs bad tests |
| [mocking.md](mocking.md) | When and how to mock; designing mockable interfaces |
| [interface-design.md](interface-design.md) | Designing interfaces for testability |
| [deep-modules.md](deep-modules.md) | Depth over breadth — small interface, deep implementation |
| [refactoring.md](refactoring.md) | What to look for in the refactor step |

## Workflow

### 1. Explore the codebase

Use a subagent to understand the existing context before writing any tests. Look for:

- Which test framework is in use? (`jest`, `pytest`, `vitest`, `xunit`, `go test`, etc.)
- How are test files structured and named? (e.g. `*.test.ts`, `tests/`, `*_test.go`)
- Are there existing similar tests to use as prior art?
- What is the module under test and what are its current dependencies?

Matching the existing patterns matters — tests that look alien to the codebase don't get maintained.

### 2. Plan

Before writing any code:

- Confirm with the user what interface changes are needed
- Confirm with the user which behaviors to test (prioritize)
- Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- Design interfaces for [testability](interface-design.md)
- List the behaviors to test as plain-English descriptions, not implementation steps
- Get user approval on the plan before writing a line

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

**Existing code with no tests?** Write characterization tests first — tests that encode the _current_ behavior without changing it. These lock in the baseline and give you a safety net before any refactoring begins. Only add new behavior after the baseline is secured.

Ask: *"What should the public interface look like? Which behaviors are most important to test?"*

### 3. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

The tracer bullet does more than verify one behavior — it proves the infrastructure works: the test runner finds tests, assertions resolve correctly, and the module under test can be imported. If it fails for non-logic reasons (import errors, configuration issues, missing test setup), you have a wiring problem to fix before any other tests will help. Isolating this risk first saves significant debugging time.

### 4. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules — and why each one matters:

- **One test at a time** — forces full understanding of one behavior before moving on; writing multiple tests at once leads to over-specifying the interface before you understand what it needs to be
- **Only enough code to pass the current test** — extra code is speculation about future requirements; without test pressure it becomes unverified complexity that accumulates into design debt
- **Don't anticipate future tests** — the interface should emerge from actual needs, not imagined ones; speculative design almost always has to be undone later
- **Keep tests focused on observable behavior** — tests tied to internal structure become a refactoring tax: every internal change requires updating tests even when no behavior changed

### 5. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- Extract duplication
- Deepen modules (move complexity behind simple interfaces)
- Apply SOLID principles where natural
- Consider what the new code reveals about adjacent existing code
- Run tests after each refactor step — each step should stay green

**Never refactor while RED.** Get to GREEN first, then clean up.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive an internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
