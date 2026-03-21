# Contributing to code-skills

Thanks for improving this toolkit. This is a curation project — quality over quantity.

## Ways to contribute

- **Add a skill** — a new `SKILL.md` for a task agents do repeatedly
- **Improve an existing skill** — clearer steps, better scope, fix a behaviour gap
- **Report a bug** — a skill producing wrong output or an agent ignoring its boundaries
- **Request a skill** — describe a repetitive task you want an agent to handle

## Before you start

- Check [open issues](../../issues) — someone may already be working on it
- For significant new skills, open an issue first to align on scope before writing

## Skill format

Every skill lives in `skills/<skill-name>/SKILL.md` and must have a YAML frontmatter block:

```yaml
---
name: my-skill
description: >-
  One or two sentences. What does this skill do and when should an agent use it?
  This text appears in skill registries — make it precise and searchable.
---
```

**Structure guidelines:**
- Lead with a `## Scope` section — define exactly what the skill does AND where it stops
- Use numbered `## Step N:` sections for sequential workflows
- End with an explicit termination: tell the agent when its work is complete
- Keep steps atomic — one clear action per step
- Reference supporting files in `skills/<name>/references/` rather than inlining large content

**Evals:** Add `skills/<name>/evals/evals.json` with at least 2 test prompts that exercise the skill. See `skills/setup-repo/evals/evals.json` for the format.

## Workflow

1. Fork the repo and create a branch: `git checkout -b feat/my-skill`
2. Add your skill under `skills/<name>/`
3. Update `README.md` to include the skill in the Skills section
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat(skill-name): add X skill`
   - `fix(skill-name): correct step N boundary`
   - `docs: update README skill catalog`
5. Open a pull request — fill in the PR template checklist

## Commit messages

This repo uses [Conventional Commits](https://www.conventionalcommits.org/). Subject line format:

```
<type>(<scope>): <short description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`
Scope: skill name, `hooks`, `readme`, or omit for repo-wide changes

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be direct, be constructive, be kind.
