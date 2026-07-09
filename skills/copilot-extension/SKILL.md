---
name: copilot-extension
description: >-
  Author, validate, and debug GitHub Copilot CLI extensions that add tools,
  commands, hooks, or session-event behavior. Use when creating or reviewing a
  Copilot CLI extension, wiring `joinSession`, deciding between project, user,
  or session scope, troubleshooting extension loading, or adding a custom
  Copilot CLI tool or slash command. Also use when the user wants a custom
  Copilot CLI extension scaffold or asks how extensions work.
---

# Copilot CLI Extension Authoring

Use this skill when creating or debugging a GitHub Copilot CLI extension that contributes tools, commands, hooks, or session-event behavior.

If the request is primarily about side-panel UI, canvas actions, or iframe lifecycle, switch to `create-canvas` and use this skill only for the surrounding extension wiring.

These snippets are small patterns, not drop-in production docs. When using one as the actual entry point, the file must be named `extension.mjs` and placed in an immediate child folder of the chosen extensions directory.

## References

Read the smallest file that answers the question:

| File | Read when |
|---|---|
| `references/minimal.mjs` | You need the smallest valid extension skeleton |
| `references/tools-pattern.mjs` | You are adding an agent-callable tool |
| `references/commands-pattern.mjs` | You are adding a slash command |
| `references/hooks-pattern.mjs` | You are adding hooks or shutdown cleanup |

These are intentionally tiny, provenance-tagged patterns - not full SDK documentation.

## Authoring workflow (do this in order)

1. **Read the bundled SDK docs first.** Call `extensions_manage({ operation: "guide" })`. At minimum review `docs/extensions.md` and `docs/agent-author.md`. For exact names or signatures, inspect the SDK type files (`index.d.ts`, `extension.d.ts`, `session.d.ts`, `types.d.ts`) instead of guessing.
2. **Decide scope, then ask if it is ambiguous.** Project scope (`.github/extensions/<name>/`) is shared with the repo. User scope (`$COPILOT_HOME/extensions/<name>/`) is personal. Session scope (`$COPILOT_HOME/session-state/<sessionId>/extensions/<name>/`) is temporary and local to the current session.
3. **Scaffold via the tool.** Call `extensions_manage({ operation: "scaffold", kind: "basic", name: "<name>", location: "project" | "user" | "session" })`. Do not hand-write the initial boilerplate unless the scaffold is clearly insufficient. For canvas work, use `kind: "canvas"` or switch to `create-canvas`.
4. **Edit `extension.mjs`.** Keep the entry file focused on wiring. Move larger helpers, renderers, or parsing logic into sibling files.
5. **Reload.** Call `extensions_reload` after every meaningful change. Otherwise you may be debugging stale code.
6. **Verify it loaded.** Call `extensions_manage({ operation: "list" })` and `extensions_manage({ operation: "inspect", name: "<name>" })`. If the extension failed to load, the inspect output and log path are the primary debugging surfaces.
7. **Drive the behavior with small tests.** Trigger one tool, one command, or one hook path at a time. Tight loops surface wiring mistakes faster than broad end-to-end prompts.

## Extension shape

A Copilot CLI extension is a Node ESM entry point that joins the runtime over JSON-RPC:

- Entry file **must** be `extension.mjs`
- Entry points must be JavaScript ESM (`extension.mjs`). You may author in TypeScript, but the runtime does not execute `.ts` files directly; transpile to ESM before shipping
- Discovery scans immediate subdirectories of:
  - `.github/extensions/`
  - `$COPILOT_HOME/extensions/`
  - `$COPILOT_HOME/session-state/<sessionId>/extensions/`
- The runtime derives `extensionId` as `${source}:${name}` (for example `project:my-extension`)
- `@github/copilot-sdk` is resolved by the CLI; do not add a `package.json` just to install it
- `stdout` is reserved for JSON-RPC. **Never `console.log`.** Use `session.log(...)`
- Tool names must be globally unique across loaded extensions

Minimal shape:

```js
import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({
    tools: [],
    commands: [],
    hooks: {},
});

session.on("session.shutdown", async () => {
    await session.log("my-extension shutting down", { ephemeral: true });
});

await session.log("my-extension loaded");
```

## API quick reference

Use these shapes as **canonical examples**, then verify exact signatures in the bundled SDK docs before relying on them.

### Tools

Use `tools` for capabilities the agent should call directly.

```js
tools: [
    {
        name: "tool_name",
        description: "What the tool does and when to call it.",
        parameters: {
            type: "object",
            properties: {
                input: { type: "string", description: "..." },
            },
            required: ["input"],
        },
        handler: async (args) => {
            return {
                textResultForLlm: "Human-readable result",
                resultType: "success",
            };
        },
    },
]
```

Most plain-text tool examples in this repo return `{ textResultForLlm, resultType }`. Treat that as a common pattern, not a contract. If you need richer result objects, verify the exact shape in the SDK docs and nearby examples before inventing one.

### Commands

Use `commands` for slash commands typed by the user, such as `/compress on`.

```js
commands: [
    {
        name: "command_name",
        description: "Short help text.",
        handler: async (context) => {
            const raw = (context.args ?? "").trim();
            await session.log(`command args: ${raw}`);
        },
    },
]
```

Commands are usually thin routers. Keep parsing near the command and push actual work into helpers.

### Hooks

Use hooks to inject context or transform behavior around the session lifecycle.

```js
hooks: {
    onSessionStart: async (data) => ({ additionalContext: "..." }),
    onPreToolUse: async (data) => ({ additionalContext: "..." }),
    onPostToolUse: async (data) => ({ modifiedResult: data.toolResult }),
    onUserPromptSubmitted: async (input) => ({ modifiedPrompt: input.prompt }),
    onErrorOccurred: async (data) => {
        await session.log(`error: ${data?.error?.message ?? "unknown"}`, { level: "warning" });
    },
}
```

Treat these as common patterns, not exhaustive guarantees:

- `onSessionStart` and `onUserPromptSubmitted` are the common places to inject `additionalContext`
- `onPostToolUse` is useful for transforming tool output
- `onErrorOccurred` should record, warn, or clean up - never hide real failures silently
- Wrap hook logic defensively; brittle hooks make the whole extension feel broken

### Session events

Use `session.on(...)` for event listeners that are clearer outside the `hooks` object. The most common proven example in the researched repos is shutdown cleanup:

```js
session.on("session.shutdown", async (event) => {
    // Flush state, close servers, write final logs, etc.
});
```

Verify the event catalog in the bundled SDK docs before assuming more event names exist.

### Canvas

Canvas work has its own surface area and failure modes. Do **not** duplicate that guidance here. Switch to `create-canvas` for:

- `createCanvas(...)`
- `open()` / `actions[]` / `onClose`
- iframe renderer flow
- canvas validation and debugging

## Common patterns

Use patterns, not pasted architecture.

1. **Prompt or result rewriting**  
   Source: `copilot-compress/extension.mjs`  
   Pattern: keep the transformation small, reversible when possible, and isolated to one hook.

2. **Context injection with dedupe**  
   Source: `copilot-kaizen/extension.mjs`  
   Pattern: inject broad guidance at session start, then inject narrower guidance only once per tool or event path.

3. **Command router with helper functions**  
   Source: `copilot-ledger/extension/extension.mjs`  
   Pattern: parse the subcommand near the slash command handler and dispatch into small, testable functions.

4. **Defensive shutdown cleanup**  
   Source: `copilot-kaizen/extension.mjs`  
   Pattern: close files, flush state, and degrade safely on shutdown. Cleanup code should not become a second source of crashes.

## Testing and verification playbook

Use this lightweight sequence every time:

1. Scaffold with `extensions_manage`
2. Edit the smallest possible behavior
3. Run `extensions_reload`
4. Run `extensions_manage list`
5. Run `extensions_manage inspect`
6. Trigger exactly one capability:
   - one tool call
   - or one slash command
   - or one hook path
7. Only broaden the scenario after the small path works

## Debugging

When something does not work, check in this order:

1. `extensions_manage({ operation: "list" })` - is the extension loaded, failed, or missing?
2. `extensions_manage({ operation: "inspect", name: "<name>" })` - read the log path and the log tail
3. `extensions_reload` - stale code is a more common bug than broken logic
4. Re-run the smallest trigger that should exercise the code path
5. If discovery still fails, confirm:
   - the file is named exactly `extension.mjs`
   - the folder is an immediate child of the discovered extensions directory
   - the extension name does not collide with another loaded extension

## Security and logging

- Never send debug output to `stdout`
- Prefer `session.log(...)` over ad-hoc shell output
- Validate user input before shelling out or touching the filesystem
- Pass user data through environment variables or structured arguments rather than interpolating it into shell snippets
- Do not log secrets, tokens, or full sensitive payloads unless the user explicitly asked for that
- Do not use extensions to replace the SDK-managed safety prompt unless you have a very strong reason and understand the consequences

## Common pitfalls

- Writing a full extension from memory without reading `extensions_manage({ operation: "guide" })`
- Using `console.log` and corrupting JSON-RPC
- Debugging before calling `extensions_reload`
- Treating commands like tools or tools like commands
- Returning an invented result shape instead of checking the SDK docs
- Duplicating canvas documentation here instead of switching to `create-canvas`
- Letting large business logic accumulate in `extension.mjs`

## Acceptance checklist

The skill is ready when it does all of the following:

- Describes tools, commands, hooks, session events, and the canvas handoff
- Stays English-only and reference-style
- Matches the create-canvas rhythm: workflow -> shape -> API -> verification -> debugging
- Uses small, provenance-tagged examples instead of large copied snippets
- Points to bundled SDK docs for exact types instead of pretending to be the SDK itself
