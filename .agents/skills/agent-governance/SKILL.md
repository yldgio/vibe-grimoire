---
name: agent-governance
description: |
  Patterns and techniques for adding governance, safety, and trust controls to AI agent systems. Use this skill when:
  - Building AI agents that call external tools (APIs, databases, file systems)
  - Implementing policy-based access controls for agent tool usage
  - Adding semantic intent classification to detect dangerous prompts
  - Creating trust scoring systems for multi-agent workflows
  - Building audit trails for agent actions and decisions
  - Enforcing rate limits, content filters, or tool restrictions on agents
  - Working with any agent framework (PydanticAI, CrewAI, OpenAI Agents, LangChain, AutoGen)
---

# Agent Governance Patterns

Patterns for adding safety, trust, and policy enforcement to AI agent systems.

## Overview

Governance patterns ensure AI agents operate within defined boundaries — controlling which tools they can call, what content they can process, how much they can do, and maintaining accountability through audit trails.

```
User Request → Intent Classification → Policy Check → Tool Execution → Audit Log
                     ↓                      ↓               ↓
              Threat Detection         Allow/Deny      Trust Update
```

## When to Use

- **Agents with tool access**: Any agent that calls external tools (APIs, databases, shell commands)
- **Multi-agent systems**: Agents delegating to other agents need trust boundaries
- **Production deployments**: Compliance, audit, and safety requirements
- **Sensitive operations**: Financial transactions, data access, infrastructure management

---

## Pattern 1: Governance Policy

Define what an agent is allowed to do as a composable, serializable policy object.

```python
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import re

class PolicyAction(Enum):
    ALLOW = "allow"
    DENY = "deny"
    REVIEW = "review"  # flag for human review

@dataclass
class GovernancePolicy:
    """Declarative policy controlling agent behavior."""
    name: str
    allowed_tools: list[str] = field(default_factory=list)
    blocked_tools: list[str] = field(default_factory=list)
    blocked_patterns: list[str] = field(default_factory=list)
    max_calls_per_request: int = 100
    require_human_approval: list[str] = field(default_factory=list)

    def check_tool(self, tool_name: str) -> PolicyAction:
        if tool_name in self.blocked_tools:
            return PolicyAction.DENY
        if tool_name in self.require_human_approval:
            return PolicyAction.REVIEW
        if self.allowed_tools and tool_name not in self.allowed_tools:
            return PolicyAction.DENY
        return PolicyAction.ALLOW

    def check_content(self, content: str) -> Optional[str]:
        for pattern in self.blocked_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                return pattern
        return None
```

## Pattern 2: Semantic Intent Classification

Detect dangerous intent in prompts before they reach the agent.

```python
THREAT_SIGNALS = [
    (r"(?i)send\s+(all|every|entire)\s+\w+\s+to\s+", "data_exfiltration", 0.8),
    (r"(?i)(rm\s+-rf|del\s+/[sq]|format\s+c:)", "system_destruction", 0.95),
    (r"(?i)ignore\s+(previous|above|all)\s+(instructions?|rules?)", "prompt_injection", 0.9),
    (r"(?i)(sudo|as\s+root|admin\s+access)", "privilege_escalation", 0.8),
]

def classify_intent(content: str) -> list[dict]:
    return [
        {"category": cat, "confidence": weight, "evidence": m.group()}
        for pattern, cat, weight in THREAT_SIGNALS
        if (m := re.search(pattern, content))
    ]
```

## Pattern 3: Tool-Level Governance Decorator

```python
def govern(policy: GovernancePolicy, audit_trail=None):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            action = policy.check_tool(func.__name__)
            if action == PolicyAction.DENY:
                raise PermissionError(f"Policy blocks tool '{func.__name__}'")
            for arg in list(args) + list(kwargs.values()):
                if isinstance(arg, str) and (matched := policy.check_content(arg)):
                    raise PermissionError(f"Blocked pattern: {matched}")
            return await func(*args, **kwargs)
        return wrapper
    return decorator
```

## Pattern 4: Trust Scoring

```python
@dataclass
class TrustScore:
    score: float = 0.5
    def record_success(self): self.score = min(1.0, self.score + 0.05 * (1 - self.score))
    def record_failure(self): self.score = max(0.0, self.score - 0.15 * self.score)
```

## Governance Levels

| Level | Controls | Use Case |
|-------|----------|----------|
| **Open** | Audit only | Internal dev/testing |
| **Standard** | Tool allowlist + content filters | General production |
| **Strict** | All controls + human approval | Financial, healthcare |
| **Locked** | Allowlist only, full audit | Compliance-critical |

## Best Practices

- Policy as configuration (YAML/JSON, not hardcoded)
- Most-restrictive-wins when composing policies
- Pre-flight intent check before tool execution
- Fail closed — if governance errors, deny the action
- Append-only audit trail for compliance
