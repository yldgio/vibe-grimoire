# Skill Authoring Patterns

Internal notes for maintainers of this repo's skills.

## Reference skills for SDK or runtime surfaces

When a skill explains how to author against an SDK, CLI, or runtime extension API:

- Mirror the target workflow order: **workflow -> shape/constraints -> API quick reference -> validation -> debugging -> pitfalls**
- Keep only the must-know shapes inline; point to the runtime's canonical docs for exact signatures and full type detail
- Prefer tiny, provenance-tagged examples over large copied snippets
- Hand off adjacent specialized surfaces to dedicated skills instead of duplicating their docs
- Include a lightweight verification loop so the skill is easy to test and maintain

The `copilot-extension` skill is the current reference example of this pattern.
