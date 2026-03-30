$ErrorActionPreference = 'Stop'

function Get-ToolCommand([object]$ToolArgs) {
    foreach ($prop in @('command','bash','powershell','input','text')) {
        $v = $ToolArgs.PSObject.Properties[$prop]
        if ($null -ne $v -and $v.Value -is [string] -and $v.Value.Trim().Length -gt 0) { return $v.Value }
    }
    return $null
}

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$payload  = $rawInput | ConvertFrom-Json
$toolName = [string]$payload.toolName
if ($toolName -notin @('bash','powershell','shell','run_terminal_cmd')) { exit 0 }

# toolArgs is a JSON string — parse it
$toolArgsRaw = [string]$payload.toolArgs
if ([string]::IsNullOrWhiteSpace($toolArgsRaw)) { exit 0 }
try { $toolArgs = $toolArgsRaw | ConvertFrom-Json } catch { exit 0 }

$command = Get-ToolCommand $toolArgs
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }
$norm = $command.ToLowerInvariant()
$normStripped = $norm -replace '"[^"]*"', '' -replace "'[^']*'", ''

$repoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
if (-not (Test-Path $policyPath)) { exit 0 }
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json

function Deny([string]$reason) {
    @{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress
    exit 0
}

$advisory = $null

foreach ($rule in $policy.extra_banned_commands) {
    $pattern = ([string]$rule.pattern).ToLowerInvariant()
    if (-not $normStripped.Contains($pattern)) { continue }
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
