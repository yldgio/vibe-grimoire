# OpenCode — Tool Guard Templates

## Files to generate

```
.opencode/plugins/tool-guard/index.ts
```

No `opencode.json` entry needed — files in `.opencode/plugins/` are loaded automatically.
OpenCode runs `.ts` files directly via Bun; no compilation step required.

## Protocol notes

- `tool.execute.before` receives `input.tool` (tool name) and `output.args` (already a parsed object)
- Deny: `throw new Error(reason)` — OpenCode surfaces the message to the AI
- Warn (block with visible advisory): same as deny, prefix reason with `⚠️ Advisory:`
- Policy is read fresh on each invocation — no restart needed after editing `policy.json`

## `.opencode/plugins/tool-guard/index.ts`

```typescript
import type { Plugin } from "@opencode-ai/plugin"
import fs from "node:fs/promises"
import path from "node:path"

type Mode = "deny" | "warn"

type CommandRule = {
  pattern: string
  match?: "contains"
  mode: Mode
  reason: string
}

type CategoryPolicy = {
  preferred: string[]
  blocked: string[]
  mode: Mode
  reason: string
}

type Policy = {
  extra_banned_commands?: CommandRule[]
  categories?: Record<string, CategoryPolicy>
}

const SHELL_TOOLS = new Set(["bash", "powershell", "run_terminal_cmd", "shell"])

function extractCommand(args: Record<string, unknown> | undefined): string | null {
  for (const key of ["command", "bash", "powershell", "input", "text"]) {
    const v = args?.[key]
    if (typeof v === "string" && v.trim().length > 0) return v
  }
  return null
}

export const ToolGuard: Plugin = async ({ worktree }) => {
  const policyPath = path.join(worktree, "hooks", "tool-guard", "policy.json")
  const policy = JSON.parse(await fs.readFile(policyPath, "utf8")) as Policy

  return {
    "tool.execute.before": async (input, output) => {
      if (!SHELL_TOOLS.has(String(input.tool ?? ""))) return

      const command = extractCommand(output.args as Record<string, unknown>)
      if (!command) return

      const norm = command.toLowerCase()

      for (const rule of policy.extra_banned_commands ?? []) {
        if (!norm.includes(rule.pattern.toLowerCase())) continue
        const msg = rule.mode === "warn" ? `⚠️ Advisory: ${rule.reason}` : rule.reason
        throw new Error(msg)
      }

      for (const [, category] of Object.entries(policy.categories ?? {})) {
        const match = category.blocked.find((p) => norm.includes(p.toLowerCase()))
        if (!match) continue
        const msg = category.mode === "warn" ? `⚠️ Advisory: ${category.reason}` : category.reason
        throw new Error(msg)
      }
    },
  }
}
```

## Notes

- The import `@opencode-ai/plugin` is resolved by OpenCode's Bun runtime — no local install needed
- The `worktree` value in `PluginInput` is the repo root — policy path resolution is always relative to it
- If `policy.json` is missing, the plugin will throw on startup; consider wrapping the `readFile` in a try/catch to fail gracefully if you want the plugin to be optional
