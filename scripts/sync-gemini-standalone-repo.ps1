#Requires -Version 5.1
# Copies gemini-signal/ (packaged Gemini extension) to a sibling repo with gemini-extension.json at ROOT
# for gallery installs: https://geminicli.com/docs/extensions/releasing
#
# Run after:  .\scripts\sync-integration-packages.ps1
# Default target:  sibling directory ..\gemini-signal (next to this repo)
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-gemini-standalone-repo.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-gemini-standalone-repo.ps1 -TargetPath D:\repos\gemini-signal

param(
  [string] $TargetPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $RepoRoot 'gemini-signal'

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
  $TargetPath = Join-Path (Split-Path -Parent $RepoRoot) 'gemini-signal'
}

if (-not (Test-Path -LiteralPath (Join-Path $src 'gemini-extension.json'))) {
  Write-Error "Missing packaged extension at $src - run sync-integration-packages.ps1 first."
  exit 1
}

if (-not (Test-Path -LiteralPath $TargetPath)) {
  New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

& robocopy.exe $src $TargetPath /E /XD '.git' /NFL /NDL /NJH /NJS
$rc = $LASTEXITCODE
if ($rc -ge 8) {
  Write-Error "robocopy failed with exit code $rc"
  exit $rc
}

Copy-Item -LiteralPath (Join-Path $RepoRoot 'templates\gemini-standalone-README.md') -Destination (Join-Path $TargetPath 'README.md') -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot 'templates\gemini-standalone-PUBLISHING.md') -Destination (Join-Path $TargetPath 'PUBLISHING.md') -Force
$licenseSrc = Join-Path $RepoRoot 'LICENSE'
if (Test-Path -LiteralPath $licenseSrc) {
  Copy-Item -LiteralPath $licenseSrc -Destination (Join-Path $TargetPath 'LICENSE') -Force
}

Write-Host ('sync-gemini-standalone-repo: OK -> ' + $TargetPath) -ForegroundColor Green
exit 0
