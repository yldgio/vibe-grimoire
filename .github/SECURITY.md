# Security Policy

## Scope

This is a configuration-only repository — it contains Markdown skill definitions, JSON policies, and shell scripts. There is no compiled code, no server, and no user data processing at the root level.

The only executable surface is the hook scripts:

- `.github/hooks/scripts/pre-tool-guard.sh` / `.ps1` — runs inside GitHub Copilot CLI sessions
- `.claude/hooks/pre-tool-guard.sh` / `.ps1` — runs inside Claude Code sessions
- `.opencode/plugins/tool-guard/index.ts` — runs inside OpenCode sessions

These scripts read `hooks/tool-guard/policy.json` and either allow or deny agent tool calls. They do not transmit data, write files, or execute network requests.

## Reporting a Vulnerability

If you find a security issue in the hook scripts (e.g., a bypass, injection via malformed tool args, or privilege escalation):

1. **Do not open a public issue.**
2. Use [GitHub private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) for this repository.
3. Include: what the issue is, how to reproduce it, and potential impact.

We'll acknowledge within 5 business days and aim to resolve within 30 days.

## Out of scope

- Issues in vendored sub-projects (`opencode-browser/`, `opencode-scheduler/`) — report those to their respective maintainers
- Skill prompt content that could be used for prompt injection — this is expected; skills are author-controlled
