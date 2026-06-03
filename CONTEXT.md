# Vibe Grimoire

A curated collection of reusable agentic skills, hooks, and agent configs for vibe coding.

## Language

**Skill**:
A reusable agent instruction set, stored as `SKILL.md` with YAML frontmatter. Invoked by a human and interpreted by an agent. The primary artifact of this repo.
_Avoid_: plugin, command, tool

**Playbook**:
A structured, machine-executable workflow definition. A graph of Phases and Tasks that `playbook-execute` runs deterministically. Stored as a `.yml` file.
_Avoid_: workflow, script, pipeline

**Phase**:
A named group of Tasks within a Playbook that share a logical objective. Phases express intent for humans; Tasks express execution for machines.
_Avoid_: stage, step (use Task for atomic steps)

**Task**:
The atomic executable unit inside a Phase. Has a unique slug `name`, a `capability`, an optional `executor`, dependency declarations, input/output contracts, an agent `prompt`, `success` criteria, and optional structured `checks`.
_Avoid_: step, action, job

**Capability**:
The stable contract of what a Task requires — independent of which agent runs it. Values: `research`, `implementation`, `verification`, `review`, `decision`. Used by `playbook-execute` when the preferred `executor` is unavailable.
_Avoid_: role, type

**Executor**:
The preferred concrete agent for a Task (e.g., `main`, `explore`, `code-review`, `human`, `custom:beck`). Optional — `playbook-execute` falls back to resolving by `capability` if absent.
_Avoid_: agent, runner

**Variables**:
Runtime inputs declared at the playbook level. Referenced as `{{ variables.<name> }}` in task `prompt` and `input` fields. An empty string default means the variable is required at runtime; a non-empty default provides a fallback value. Collected from the developer by `playbook-execute` before execution starts.
_Avoid_: params, arguments

**checks**:
Optional typed verification steps on a Task, run by `playbook-execute` after execution to confirm success. All listed checks must pass. Types: `file_exists`, `file_contains`, `command`, `human`, `agent_confirms`. When absent, `playbook-execute` applies its judgment protocol to evaluate the `success` field.
_Avoid_: tests, assertions

**playbook-design**:
The skill that interviews a user and produces a Playbook `.yml` file. Design-time artifact.

**playbook-execute**:
The skill that reads a Playbook `.yml` file and runs its Tasks in dependency order, delegating to the appropriate executor per task.

## Relationships

- A **Playbook** contains one or more **Phases** (optional in execution, always present when designed with `playbook-design`)
- A **Playbook** may declare **Variables** (runtime inputs substituted before execution)
- A **Phase** contains one or more **Tasks**
- A **Task** declares its **Capability** (required) and preferred **Executor** (optional)
- A **Task** may depend on other **Tasks** via `depends_on` (list of Task `name` slugs)
- A **Task** may include optional **checks** (typed verification steps run after execution)
- **playbook-design** produces a **Playbook**; **playbook-execute** consumes it

## Example dialogue

> **Dev:** "Should the Playbook have phases or just a flat list of tasks?"
> **Domain expert:** "Phases — they express intent and ordering for humans. Tasks are the executable units. A Phase without Tasks is documentation; a Task without a Phase has no context."

## Flagged ambiguities

- "step" was used ambiguously for both Phase and Task — resolved: Phase = logical group, Task = atomic unit.
- "workflow" was considered as a name for Playbook — resolved: Playbook is preferred, avoids confusion with CI/CD system workflows.
