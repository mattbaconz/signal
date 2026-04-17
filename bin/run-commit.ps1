#Requires -Version 5.1
# Forward to bundled signal-commit script. Invoke with cwd = git repository root.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File bin/run-commit.ps1 [--draft] [--dry] [--] "message"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ExtensionRoot = Split-Path $PSScriptRoot -Parent
$CommitPs1 = Join-Path $ExtensionRoot 'skills\signal-commit\scripts\commit.ps1'
if (-not (Test-Path -LiteralPath $CommitPs1)) {
  Write-Host "x missing bundled script: $CommitPs1" -ForegroundColor Red
  exit 1
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $CommitPs1 @args
exit $LASTEXITCODE
