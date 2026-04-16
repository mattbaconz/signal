#Requires -Version 5.1
# Copy canonical skill folders into gemini-signal/skills and claude-signal/skills.
# Run from repo root:  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-integration-packages.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $RepoRoot 'signal\SKILL.md'))) {
  Write-Error "Run from SIGNAL repo root (signal\SKILL.md not found)."
  exit 1
}

$skillDirs = @('signal', 'signal-commit', 'signal-push', 'signal-pr', 'signal-review', 'signal-ckpt')
$targets = @(
  (Join-Path $RepoRoot 'gemini-signal\skills'),
  (Join-Path $RepoRoot 'claude-signal\skills')
)

foreach ($destRoot in $targets) {
  if (-not (Test-Path $destRoot)) {
    New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
  }
  foreach ($name in $skillDirs) {
    $src = Join-Path $RepoRoot $name
    $dst = Join-Path $destRoot $name
    if (-not (Test-Path $src)) {
      Write-Error "Missing skill folder: $src"
      exit 1
    }
    if (Test-Path $dst) {
      Remove-Item -LiteralPath $dst -Recurse -Force
    }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    Write-Host "  synced $name -> $destRoot"
  }
}

Write-Host "sync-integration-packages: OK" -ForegroundColor Green
exit 0
