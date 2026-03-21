## Summary

<!-- What does this PR do? One or two sentences. -->

## Type of change

- [ ] New skill (`feat(skill-name): ...`)
- [ ] Skill fix / improvement (`fix(skill-name): ...`)
- [ ] Hook or policy change (`fix(hooks): ...`)
- [ ] Documentation only (`docs: ...`)
- [ ] Chore (`chore: ...`)

## Checklist

### For skill changes
- [ ] `SKILL.md` has `name` and `description` frontmatter
- [ ] Skill has a `## Scope` section that defines where it stops
- [ ] Final step explicitly returns control to the user
- [ ] Evals added or updated in `skills/<name>/evals/evals.json` (minimum 2 prompts)
- [ ] Skill tested manually in at least one runtime (Copilot CLI / OpenCode / Claude Code)
- [ ] `README.md` updated if this is a new skill

### For hook/policy changes
- [ ] `hooks/tool-guard/policy.json` is the only source of truth (no hardcoded rules in scripts)
- [ ] Both `.sh` and `.ps1` variants updated if scripts changed
- [ ] Tested with a deny-mode command to confirm enforcement works

### All PRs
- [ ] Commit message follows Conventional Commits (`type(scope): description`)
- [ ] No unrelated files changed
