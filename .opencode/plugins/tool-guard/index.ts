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

function extractCommand(output: { args?: Record<string, unknown> } | undefined): string | null {
  const candidates = [
    output?.args?.command,
    output?.args?.bash,
    output?.args?.powershell,
    output?.args?.input,
    output?.args?.text,
  ]

  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim().length > 0) {
      return candidate
    }
  }

  return null
}

export const ToolGuard: Plugin = async ({ client, worktree }) => {
  const policyPath = path.join(worktree, "hooks", "tool-guard", "policy.json")
  const policy = JSON.parse(await fs.readFile(policyPath, "utf8")) as Policy

  return {
    "tool.execute.before": async (input, output) => {
      if (!SHELL_TOOLS.has(String(input.tool ?? ""))) {
        return
      }

      const command = extractCommand(output)
      if (!command) {
        return
      }

      const normalizedCommand = command.toLowerCase()

      for (const rule of policy.extra_banned_commands ?? []) {
        if (rule.mode !== "deny") {
          continue
        }

        if (normalizedCommand.includes(rule.pattern.toLowerCase())) {
          throw new Error(rule.reason)
        }
      }

      for (const [categoryName, category] of Object.entries(policy.categories ?? {})) {
        if (category.mode !== "warn") {
          continue
        }

        const matchedPattern = category.blocked.find((pattern) =>
          normalizedCommand.includes(pattern.toLowerCase()),
        )

        if (!matchedPattern) {
          continue
        }

        await client.app.log({
          body: {
            service: "tool-guard",
            level: "warn",
            message: category.reason,
            extra: {
              category: categoryName,
              pattern: matchedPattern,
              command,
            },
          },
        })
      }
    },
  }
}
