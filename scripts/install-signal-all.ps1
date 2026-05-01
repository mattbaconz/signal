#Requires -Version 5.1
# Copy SIGNAL skills into common user-level agent skill folders.
# Optional -AlwaysOn installs short host instruction files so SIGNAL-3 is the default.
# Run: powershell -ExecutionPolicy Bypass -File .\scripts\install-signal-all.ps1 -AlwaysOn
[CmdletBinding()]
param(
  [Alias('Host')]
  [ValidateSet('All', 'Claude', 'Codex', 'Gemini', 'Cursor')]
  [string[]]$TargetHost = @('All'),

  [switch]$AlwaysOn,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$skillSrcRoot = Join-Path $repoRoot 'claude-signal\skills'
$templateBody = Join-Path $repoRoot 'templates\host-always-on.body.md'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path (Join-Path $skillSrcRoot 'signal\SKILL.md'))) {
  throw "Could not find $skillSrcRoot\signal\SKILL.md. Clone SIGNAL and run sync-integration-packages.ps1 if mirrors are missing."
}

function Test-SelectedHost([string]$Name) {
  return ($TargetHost -contains 'All' -or $TargetHost -contains $Name)
}

function Invoke-CopyDirectory {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Label
  )
  Write-Host "$Label -> $Dst" -ForegroundColor Cyan
  if ($DryRun) { return }
  $parent = Split-Path -Parent $Dst
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  if (Test-Path -LiteralPath $Dst) {
    Remove-Item -LiteralPath $Dst -Recurse -Force
  }
  Copy-Item -LiteralPath $Src -Destination $Dst -Recurse -Force
}

function Set-MarkedBlock {
  param(
    [string]$Path,
    [string]$Content,
    [string]$Label
  )
  $start = '<!-- SIGNAL:BEGIN -->'
  $end = '<!-- SIGNAL:END -->'
  $block = "$start`n$Content`n$end`n"
  Write-Host "$Label -> $Path" -ForegroundColor Cyan
  if ($DryRun) { return }
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $existing = if (Test-Path -LiteralPath $Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding utf8
  } else {
    ''
  }
  $pattern = '(?s)<!-- SIGNAL:BEGIN -->.*?<!-- SIGNAL:END -->\s*'
  if ($existing -match $pattern) {
    $next = [regex]::Replace($existing, $pattern, $block)
  } else {
    $prefix = if ([string]::IsNullOrWhiteSpace($existing)) { '' } else { $existing.TrimEnd() + "`n`n" }
    $next = $prefix + $block
  }
  [System.IO.File]::WriteAllText($Path, $next, $utf8NoBom)
}

$targets = @()
if (Test-SelectedHost 'Gemini') {
  $targets += @{ Path = Join-Path $env:USERPROFILE '.agents\skills'; Name = 'Universal .agents (Gemini + others)' }
}
if (Test-SelectedHost 'Claude') {
  $targets += @{ Path = Join-Path $env:USERPROFILE '.claude\skills'; Name = 'Claude Code' }
}
if (Test-SelectedHost 'Cursor') {
  $targets += @{ Path = Join-Path $env:USERPROFILE '.cursor\skills'; Name = 'Cursor' }
}
if (Test-SelectedHost 'Codex') {
  $targets += @{ Path = Join-Path $env:USERPROFILE '.codex\skills'; Name = 'OpenAI Codex' }
}

Get-ChildItem -Path $skillSrcRoot -Directory | ForEach-Object {
  foreach ($t in $targets) {
    $dst = Join-Path $t.Path $_.Name
    Invoke-CopyDirectory -Src $_.FullName -Dst $dst -Label "$($t.Name) skill $($_.Name)"
  }
}

if ($AlwaysOn) {
  if (-not (Test-Path -LiteralPath $templateBody)) {
    throw "Missing always-on template: $templateBody"
  }
  $body = Get-Content -LiteralPath $templateBody -Raw -Encoding utf8
  if (Test-SelectedHost 'Claude') {
    Set-MarkedBlock -Path (Join-Path $env:USERPROFILE '.claude\CLAUDE.md') -Content $body -Label 'Claude always-on'
  }
  if (Test-SelectedHost 'Gemini') {
    Set-MarkedBlock -Path (Join-Path $env:USERPROFILE '.gemini\GEMINI.md') -Content $body -Label 'Gemini always-on'
  }
  if (Test-SelectedHost 'Codex') {
    Set-MarkedBlock -Path (Join-Path $env:USERPROFILE '.codex\AGENTS.md') -Content $body -Label 'Codex always-on'
  }
  if (Test-SelectedHost 'Cursor') {
    $cursor = "---`ndescription: SIGNAL workspace defaults`nalwaysApply: true`n---`n`n$body"
    Set-MarkedBlock -Path (Join-Path $env:USERPROFILE '.cursor\rules\signal.mdc') -Content $cursor -Label 'Cursor always-on'
  }
}

Write-Host ''
if ($DryRun) {
  Write-Host 'Dry run complete. No files changed.' -ForegroundColor Yellow
} else {
  Write-Host 'Done. SIGNAL skills installed.' -ForegroundColor Green
}
Write-Host 'Use normal prompts. Always-on hosts should default to SIGNAL-3; type signal3 or /signal3 to reset the tier.' -ForegroundColor Green
