---
name: pre-mortem
description: >-
  Run a pre-mortem on a plan or design: assume it failed, then relentlessly
  interrogate every branch of the decision tree to find out why — and fix it
  before you start. Use when the user wants to stress-test a plan, asks you to
  "ask me", says "interrogami" or "fammi domande", mentions "pre-mortem",
  "design of design", or wants rigorous design discovery before implementation.
---

Interview me relentlessly about every aspect of a plan or idea until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead. always use subagents to explore the codebase.
Never apply changes to the codebase directly from this skill. 
Always output a plan or design and offer to save it to a file named `{project_name}-design.md` in the current working directory.
