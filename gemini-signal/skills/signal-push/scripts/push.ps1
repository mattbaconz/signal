#Requires -Version 5.1
<#
.SYNOPSIS
  Commit then push (Windows-native). Mirrors push.sh — wraps commit.ps1 with a push step.

  Usage:
    .\push.ps1 [--draft] [--split] [--dry] [--] "commit message"
#>
Set-StrictMode -Version Latest
# Git writes to stderr even on success; do not treat stderr as a terminating error.
$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommitScript = Join-Path $ScriptDir '..\..\signal-commit\scripts\commit.ps1'
if (-not (Test-Path -LiteralPath $CommitScript)) {
  Write-Host "x commit.ps1 not found: $CommitScript"
  exit 1
}
$CommitScript = (Resolve-Path -LiteralPath $CommitScript).Path

$Draft = $false
$Dry = $false
$Split = $false
$Msg = $null
$argv = @($args)
$i = 0
while ($i -lt $argv.Count) {
  switch ($argv[$i]) {
    '--draft' { $Draft = $true; $i++; continue }
    '--dry'   { $Dry = $true;   $i++; continue }
    '--split' { $Split = $true; $i++; continue }
    '--' {
      $i++
      if ($i -lt $argv.Count) { $Msg = ($argv[$i..($argv.Count - 1)] -join ' ') }
      $i = $argv.Count
      break
    }
    default {
      if ($argv[$i] -like '-*') {
        Write-Host "x unknown flag: $($argv[$i])"
        exit 1
      }
      $Msg = ($argv[$i..($argv.Count - 1)] -join ' ')
      $i = $argv.Count
      break
    }
  }
}

if ([string]::IsNullOrWhiteSpace($Msg)) {
  try {
    if ([Console]::IsInputRedirected) {
      $stdin = [Console]::In.ReadToEnd()
      if (-not [string]::IsNullOrWhiteSpace($stdin)) { $Msg = $stdin.TrimEnd() }
    }
  } catch { }
}

git rev-parse --git-dir *>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x not a git repository'
  exit 1
}

$detached = $false
try {
  git symbolic-ref -q HEAD 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { $detached = $true }
} catch { $detached = $true }

if ($detached -and $Dry) {
  Write-Host 'x cannot push in detached HEAD - checkout a branch first'
  exit 0
}

git remote get-url origin *>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x no remote configured - add remote first'
  exit 1
}

$pass = @()
if ($Dry) { $pass += '--dry' }
if ($Split) { $pass += '--split' }

if ($Dry) {
  $branch = git rev-parse --abbrev-ref HEAD 2>$null
  if ($LASTEXITCODE -ne 0) { $branch = 'HEAD' }
  & $CommitScript @pass '--' $Msg
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host "Would push -> origin/$branch"
  exit 0
}

if ($Draft) {
  & $CommitScript '--draft' '--' $Msg
  exit $LASTEXITCODE
}

& $CommitScript @pass '--' $Msg
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $branch -or $branch -eq 'HEAD') {
  Write-Host 'x cannot push in detached HEAD - checkout a branch first'
  exit 1
}

git push *>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "+ pushed -> origin/$branch"
  exit 0
}

git push --set-upstream origin $branch *>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "+ pushed -> origin/$branch"
  exit 0
}

Write-Host 'x push rejected - pull and rebase first'
exit 1
