# Tool Guard

Canonical tool policy for this repository.

This repo is a configuration-only collection of skills, hooks, and agents. It has no build step, no package-install workflow, and no test runner to invoke during routine maintenance.

The source of truth lives in `hooks/tool-guard/policy.json`.

Runtime-native enforcement is generated for:

- GitHub Copilot CLI in `.github/hooks/`
- OpenCode in `.opencode/plugins/`

Policy intent:

- warn on package-manager, task-runner, formatter, linter, and test-runner commands that do not fit this repo
- deny clearly destructive git cleanup/reset commands unless a user explicitly asks for them

The runtime hooks are intentionally narrow. They enforce deny rules directly and keep warning-only guidance lightweight so repo-specific customization can evolve without aggressive blocking.
