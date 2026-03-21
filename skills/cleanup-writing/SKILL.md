---
name: cleanup-writing
description: >-
  Edit and improve writing by restructuring sections, clarifying prose, and
  tightening flow. Use when the user wants to edit, revise, polish, proofread,
  or improve a draft; says "clean up my writing", "make this clearer", "this
  sounds awkward", "tighten this up", "make it more concise", "does this flow
  well?", or asks for help with an email, README, blog post, PR description,
  technical doc, or any piece of prose.
---

# Cleanup Writing

Edit and improve a piece of writing section by section — fixing information order, improving clarity, and tightening prose — then deliver the full revised document.

## Process

### 1. Structure the document

Divide the writing into sections based on its headings. If no headings are present, propose a logical division based on content and flow.

Before confirming the structure, check the information ordering: readers need concept A before concept B can land, so no section should assume knowledge that hasn't been introduced yet. Think of this as a dependency chain — earlier sections must establish everything that later sections rely on. Reorder or flag any sections that violate this.

### 2. Confirm the plan

Present the proposed section breakdown and order to the user. If the user disagrees, revise the structure before rewriting anything — rewriting in the wrong structure wastes effort.

### 3. Rewrite each section

For each section in order:

- Rewrite to improve clarity, coherence, and flow
- Keep paragraphs short — no more than 240 characters each. Short paragraphs reduce cognitive load, force one idea per paragraph, and keep readers moving forward; long paragraphs bury the point
- Cut filler words, passive voice, and redundant phrases
- Preserve the author's voice — edit, don't replace

### 4. Deliver the revised document

Output the **complete revised document** in full. Do not output only the changed sections — the user needs to see how the whole piece reads together as a continuous flow.

After delivering, ask: *"Would you like me to adjust the tone, tighten any section further, or rethink the structure?"*