$ErrorActionPreference = 'Stop'

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$payload = $rawInput | ConvertFrom-Json
if ($payload.tool_name -ne 'Bash') { exit 0 }

# tool_input is already a parsed object
$command = $payload.tool_input?.command
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }
$norm = $command.ToLowerInvariant()
$normStripped = $norm -replace '"[^"]*"', '' -replace "'[^']*'", ''

$repoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
if (-not (Test-Path $policyPath)) { exit 0 }
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json

function Deny([string]$reason) {
    @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Depth 3 -Compress
    exit 0
}

$advisory = $null

foreach ($rule in $policy.extra_banned_commands) {
    if (-not $normStripped.Contains(([string]$rule.pattern).ToLowerInvariant())) { continue }
    if ([string]$rule.mode -eq 'warn') {
        if ([string]::IsNullOrWhiteSpace($advisory)) { $advisory = "⚠️ Advisory: $([string]$rule.reason)" }
        continue
    }
    Deny ([string]$rule.reason)
}

foreach ($prop in $policy.categories.PSObject.Properties) {
    $cat    = $prop.Value
    $mode   = [string]$cat.mode
    $reason = [string]$cat.reason
    foreach ($pattern in $cat.blocked) {
        if (-not $normStripped.Contains($pattern.ToLowerInvariant())) { continue }
        if ($mode -eq 'warn') {
            if ([string]::IsNullOrWhiteSpace($advisory)) { $advisory = "⚠️ Advisory: $reason" }
            continue
        }
        Deny $reason
    }
}

if (-not [string]::IsNullOrWhiteSpace($advisory)) { [Console]::Error.WriteLine($advisory) }
exit 0
