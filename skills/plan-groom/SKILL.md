---
name: plan-groom
description: >-
  Relentlessly interrogate a user's plan or design until you reach shared understanding,
  walking every branch of the decision tree and resolving dependencies one-by-one. Use
  this when the user wants to stress-test a plan, get questioned on a design, asks you
  to "ask me", says "interrogami" or "fammi domande", mentions "design of design", or
  wants rigorous design discovery before planning an implementation.
---

Interview me relentlessly about every aspect of a plan or idea until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead. always use subagents to explore the codebase.
Never apply changes to the codebase directly from this skill. 
Always output a plan or design and offer to save it to a file named `{project_name}-design.md` in the current working directory.
