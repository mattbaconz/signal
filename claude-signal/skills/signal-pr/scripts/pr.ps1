#Requires -Version 5.1
<#
.SYNOPSIS
  Commit, push, then open a PR via gh (Windows-native). Mirrors pr.sh.

  Usage:
    .\pr.ps1 [--draft] [--dry] [--pr-draft] [--title "PR title"] [--body "PR body"] [--] "commit message"
#>
Set-StrictMode -Version Latest
# Git and gh write to stderr; do not treat stderr as a terminating error.
$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PushScript = Join-Path $ScriptDir '..\..\signal-push\scripts\push.ps1'
if (-not (Test-Path -LiteralPath $PushScript)) {
  Write-Host "x push.ps1 not found: $PushScript"
  exit 1
}
$PushScript = (Resolve-Path -LiteralPath $PushScript).Path

$Draft = $false
$Dry = $false
$PrDraft = $false
$PrTitle = $null
$PrBody = $null
$CommitMsg = $null
$PushFlags = [System.Collections.ArrayList]::new()

$argv = @($args)
$i = 0
while ($i -lt $argv.Count) {
  switch ($argv[$i]) {
    '--draft' {
      [void]$PushFlags.Add('--draft')
      $Draft = $true
      $i++
      continue
    }
    '--dry' {
      [void]$PushFlags.Add('--dry')
      $Dry = $true
      $i++
      continue
    }
    '--pr-draft' { $PrDraft = $true; $i++; continue }
    '--title' {
      if ($i + 1 -ge $argv.Count) { Write-Host 'x --title requires a value'; exit 1 }
      $PrTitle = $argv[$i + 1]
      $i += 2
      continue
    }
    '--body' {
      if ($i + 1 -ge $argv.Count) { Write-Host 'x --body requires a value'; exit 1 }
      $PrBody = $argv[$i + 1]
      $i += 2
      continue
    }
    '--' {
      $i++
      if ($i -lt $argv.Count) { $CommitMsg = ($argv[$i..($argv.Count - 1)] -join ' ') }
      $i = $argv.Count
      break
    }
    default {
      if ($argv[$i] -like '-*') {
        Write-Host "x unknown flag: $($argv[$i])"
        exit 1
      }
      $CommitMsg = ($argv[$i..($argv.Count - 1)] -join ' ')
      $i = $argv.Count
      break
    }
  }
}

if ([string]::IsNullOrWhiteSpace($CommitMsg)) {
  try {
    if ([Console]::IsInputRedirected) {
      $stdin = [Console]::In.ReadToEnd()
      if (-not [string]::IsNullOrWhiteSpace($stdin)) { $CommitMsg = $stdin.TrimEnd() }
    }
  } catch { }
}

git rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host '✗ not a git repository'
  exit 1
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
  Write-Host 'x gh CLI required - install from https://cli.github.com'
  exit 1
}

gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x gh not authenticated - run: gh auth login'
  exit 1
}

if ($Draft) {
  Write-Host 'Draft commit message:'
  Write-Host "  $CommitMsg"
  Write-Host ''
  if ($PrTitle) {
    Write-Host 'Draft PR title:'
    Write-Host "  $PrTitle"
    Write-Host ''
  }
  if ($PrBody) {
    Write-Host 'Draft PR body:'
    $PrBody -split "`n" | ForEach-Object { Write-Host "  $_" }
    Write-Host ''
  }
  Write-Host 'Run /signal-pr to confirm.'
  exit 0
}

if ($Dry) {
  $pf = @($PushFlags | ForEach-Object { $_ })
  & $PushScript @pf '--' $CommitMsg
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $title = $PrTitle
  if ([string]::IsNullOrWhiteSpace($title)) { $title = $CommitMsg }
  Write-Host "Would create PR: `"$title`""
  if ($PrDraft) { Write-Host 'Would create as draft PR' }
  exit 0
}

$branch = git rev-parse --abbrev-ref HEAD 2>$null
$existing = gh pr view $branch --json url --jq '.url' 2>$null
if ($LASTEXITCODE -eq 0 -and $existing) {
  $existing = $existing.Trim()
  Write-Host "x PR already open for this branch -> $existing"
  exit 1
}

$pushArgs = @($PushFlags | ForEach-Object { $_ })
& $PushScript @pushArgs '--' $CommitMsg
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ([string]::IsNullOrWhiteSpace($PrTitle)) { $PrTitle = $CommitMsg }

if ([string]::IsNullOrWhiteSpace($PrBody)) {
  $type = 'chore'
  if ($CommitMsg -match "^([a-z]+)") { $type = $Matches[1] }
  $PrBody = @"
## Changes
- $CommitMsg

## Type
$type
"@
}

$ghArgs = @('pr', 'create', '--title', $PrTitle, '--body', $PrBody)
if ($PrDraft) { $ghArgs += '--draft' }

$prUrl = (& gh @ghArgs 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x gh pr create failed'
  exit 1
}
Write-Host "+ PR opened -> $prUrl"
