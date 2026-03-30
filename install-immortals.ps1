<#
.SYNOPSIS
    Installs "The Immortals" skills and agents into your project.

.DESCRIPTION
    Downloads skill SKILL.md files and agent .md files from the vibe-grimoire
    repository and places them in the appropriate directories relative to the
    current working directory (your project root).

    Skills are installed to:   .agents/skills/<name>/SKILL.md
    Agents are installed to:   .github/agents/<name>.agent.md

.EXAMPLE
    # Run from your project root:
    pwsh -NoProfile -ExecutionPolicy Bypass -File install-immortals.ps1

.EXAMPLE
    # Or dot-source it interactively:
    . .\install-immortals.ps1
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

$BaseUrl = 'https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/'

$Skills = @(
    @{ Src = 'skills/design-patterns/SKILL.md';        Dest = '.agents/skills/design-patterns/SKILL.md' }
    @{ Src = 'skills/clean-code/SKILL.md';             Dest = '.agents/skills/clean-code/SKILL.md' }
    @{ Src = 'skills/refactoring/SKILL.md';            Dest = '.agents/skills/refactoring/SKILL.md' }
    @{ Src = 'skills/domain-driven-design/SKILL.md';   Dest = '.agents/skills/domain-driven-design/SKILL.md' }
    @{ Src = 'skills/performance-review/SKILL.md';     Dest = '.agents/skills/performance-review/SKILL.md' }
    @{ Src = 'skills/the-immortals/SKILL.md';          Dest = '.agents/skills/the-immortals/SKILL.md' }
)

$Agents = @(
    @{ Src = '.github/agents/fowler.agent.md';          Dest = '.github/agents/fowler.agent.md' }
    @{ Src = '.github/agents/beck.agent.md';            Dest = '.github/agents/beck.agent.md' }
    @{ Src = '.github/agents/uncle-bob.agent.md';       Dest = '.github/agents/uncle-bob.agent.md' }
    @{ Src = '.github/agents/evans.agent.md';           Dest = '.github/agents/evans.agent.md' }
    @{ Src = '.github/agents/linus.agent.md';           Dest = '.github/agents/linus.agent.md' }
    @{ Src = '.github/agents/the-immortals.agent.md';   Dest = '.github/agents/the-immortals.agent.md' }
)

$skillsInstalled = 0
$agentsInstalled = 0
$skipped = 0

function Install-File {
    param(
        [string]$Url,
        [string]$DestRelative,
        [string]$Kind
    )

    $destPath = Join-Path $PWD $DestRelative

    if (Test-Path $destPath) {
        $answer = Read-Host "Overwrite $DestRelative? [y/N]"
        if ($answer -notmatch '^[Yy]$') {
            Write-Host "  Skipped: $DestRelative"
            return 'skipped'
        }
    }

    try {
        $dir = Split-Path $destPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Invoke-WebRequest -Uri $Url -OutFile $destPath -UseBasicParsing
        Write-Host "  Installed: $DestRelative"
        return 'installed'
    }
    catch {
        Write-Host "  ERROR downloading ${DestRelative}: $_" -ForegroundColor Red
        return 'skipped'
    }
}

Write-Host ""
Write-Host "=== Installing The Immortals ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "-- Skills --" -ForegroundColor Yellow
foreach ($skill in $Skills) {
    $url = $BaseUrl + $skill.Src
    $result = Install-File -Url $url -DestRelative $skill.Dest -Kind 'skill'
    if ($result -eq 'installed') { $skillsInstalled++ } else { $skipped++ }
}

Write-Host ""
Write-Host "-- Agents --" -ForegroundColor Yellow
foreach ($agent in $Agents) {
    $url = $BaseUrl + $agent.Src
    $result = Install-File -Url $url -DestRelative $agent.Dest -Kind 'agent'
    if ($result -eq 'installed') { $agentsInstalled++ } else { $skipped++ }
}

Write-Host ""
Write-Host "✅ $skillsInstalled skills installed, $agentsInstalled agents installed, $skipped skipped." -ForegroundColor Green
Write-Host "For Claude Code & OpenCode, see https://github.com/yldgio/vibe-grimoire/blob/main/docs/installing-agents.md"
Write-Host ""
