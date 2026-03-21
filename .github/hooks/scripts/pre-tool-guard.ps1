$ErrorActionPreference = 'Stop'

function Get-NormalizedCommand {
    param(
        [Parameter(Mandatory = $false)]
        [object]$ToolArgs
    )

    if ($null -eq $ToolArgs) {
        return $null
    }

    foreach ($propertyName in @('command', 'bash', 'powershell', 'input', 'text')) {
        $property = $ToolArgs.PSObject.Properties[$propertyName]
        if ($null -ne $property -and $property.Value -is [string] -and -not [string]::IsNullOrWhiteSpace($property.Value)) {
            return $property.Value
        }
    }

    return $null
}

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

$payload = $rawInput | ConvertFrom-Json
$toolName = [string]$payload.toolName
if ($toolName -notin @('bash', 'powershell', 'run_terminal_cmd', 'shell')) {
    exit 0
}

$toolArgsText = [string]$payload.toolArgs
if ([string]::IsNullOrWhiteSpace($toolArgsText)) {
    exit 0
}

$toolArgs = $toolArgsText | ConvertFrom-Json
$command = Get-NormalizedCommand -ToolArgs $toolArgs
if ([string]::IsNullOrWhiteSpace($command)) {
    exit 0
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json
$normalizedCommand = $command.ToLowerInvariant()

foreach ($rule in $policy.extra_banned_commands) {
    if ($rule.mode -ne 'deny') {
        continue
    }

    $pattern = [string]$rule.pattern
    if ([string]::IsNullOrWhiteSpace($pattern)) {
        continue
    }

    if ($normalizedCommand.Contains($pattern.ToLowerInvariant())) {
        @{
            permissionDecision = 'deny'
            permissionDecisionReason = [string]$rule.reason
        } | ConvertTo-Json -Compress
        exit 0
    }
}

exit 0
