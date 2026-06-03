# Playbook files are pure YAML, not Markdown

Playbooks are machine-executable workflow graphs, not narrative documentation. They are stored as `.yml` files — not as `SKILL.md`-style Markdown — because `playbook-execute` must parse them deterministically without LLM interpretation. Rich or reusable `prompt` content is kept in separate `.md` files and referenced via `!include <path>`.

## Considered options

- **Markdown + YAML frontmatter** (SKILL.md pattern): rejected because Skills are human-invoked instructions; Playbooks are machine-consumed graphs. Mixing narrative structure with executable structure forces the executor to interpret instead of parse.
- **Hybrid Markdown with fenced YAML task blocks**: rejected for the same reason — the executor's behavior changes depending on how faithfully it parses the surrounding prose.
- **Pure YAML**: chosen. Matches the established pattern for workflow definitions (GitHub Actions, Ansible, CircleCI). Unambiguous for both human authors and the `playbook-execute` skill.

## Consequences

Prompt text that is too long to inline comfortably in YAML can be extracted to a `.md` file and referenced with `!include <relative-path>`. This keeps the graph clean while allowing rich instructions where needed.
