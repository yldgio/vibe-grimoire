---
name: design-it-twice
description: >-
  Generate multiple radically different interface designs for a module using
  parallel sub-agents, then compare and synthesize. Use when the user wants to
  design an API, explore interface options, compare module shapes, asks "how
  should I structure this", "what's the best shape for this module", "should
  this be one function or two", "I can't decide between these approaches",
  mentions "interface design", "API design", "module interface", "how should I
  model this", "what should I expose", or says "design it twice".
---

# Design It Twice

Based on "Design It Twice" from *A Philosophy of Software Design*: your first idea is unlikely to be your best. Generate multiple radically different designs in parallel, then compare and synthesize.

## Workflow

### 1. Gather requirements

Before designing, understand:

- What problem does this module solve?
- Who are the callers? (other modules, external users, tests)
- What are the key operations?
- Any constraints? (performance, compatibility, existing patterns)
- What should be hidden inside vs exposed at the interface?

### 2. Explore the codebase *(if applicable)*

If the module is part of an existing codebase, use a subagent to explore it first. Look for:

- Sibling modules with similar responsibilities — their interface shapes set a precedent
- Existing naming conventions and patterns the new interface should follow
- How likely callers are structured — their needs should drive the design

Designing without this context risks a design that fits the problem in isolation but clashes with the codebase it lives in.

### 3. Generate designs in parallel

Spawn **3 sub-agents simultaneously** using the Task tool. Each must produce a **radically different** approach — the value is in contrast, not consensus. Assign a different constraint axis to each agent to guarantee divergence:

```
Design an interface for: [module description]

Requirements: [gathered requirements]

Your constraint: [one of the following, one per agent]
- Agent 1: "Minimize method count — aim for 1–3 methods maximum"
- Agent 2: "Maximize flexibility — design for as many use cases as possible"
- Agent 3: "Optimize for the single most common use case — everything else is secondary"

Output:
1. Interface signature (types, methods, params)
2. Usage example — how a caller uses it in practice
3. What this design hides internally
4. Trade-offs of this approach
```

### 4. Present all designs

Show each design with its interface signature, usage example, and what it hides. Present all three designs before moving to comparison — the user should absorb each approach on its own before evaluating them against each other.

### 5. Compare designs

Compare the three designs on:

- **Depth**: Does the interface hide significant complexity (deep module — good) or expose thin implementation (shallow module — avoid)?
- **Interface simplicity**: Fewer methods and simpler params = easier to learn and harder to misuse
- **General-purpose vs specialized**: Flexibility for future use cases vs focus on the current one
- **Implementation efficiency**: Does the interface shape allow an efficient implementation, or force awkward internals?
- **Ease of correct use** vs **ease of misuse**

Write the comparison in **prose, not a table**. Tables invite checkbox thinking ("A wins here, B wins there") — prose forces you to synthesize the trade-offs and form an actual recommendation.

### 6. Synthesize

The best design often combines insights from multiple options. Ask:

- *"Which design best fits your primary use case?"*
- *"Are there elements from the other designs worth incorporating?"*

Offer to produce a hybrid design if the user sees value in combining approaches.

## Anti-patterns

- **Don't let sub-agents produce similar designs** — enforce the constraint axes; similar designs defeat the purpose
- **Don't skip the comparison** — the value is in the contrast, not the designs themselves
- **Don't implement** — this skill is purely about interface shape, not internal logic
- **Don't evaluate on implementation effort** — ease of building is not a design criterion