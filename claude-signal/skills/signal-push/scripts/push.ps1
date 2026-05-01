#Requires -Version 5.1
# SIGNAL v0.4.0 - push.ps1
# Usage: .\push.ps1 [--draft] [--split] [--dry] [--] "message"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$repoSkills = Split-Path (Split-Path $scriptDir -Parent) -Parent
$commitScript = Join-Path $repoSkills 'signal-commit\scripts\commit.ps1'
if (-not (Test-Path -LiteralPath $commitScript)) {
  Write-Host "x missing commit script: $commitScript"
  exit 1
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $commitScript --push @args
exit $LASTEXITCODE
