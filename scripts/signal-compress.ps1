#Requires -Version 5.1
# SIGNAL - signal-compress helper.
# Backs up a memory / notes file ("<name>.original.md") so the user can safely
# rewrite the original with the SIGNAL-1 compression prompt (see
# templates/signal-compress-prompt.md and docs/signal-compress.md).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\signal-compress.ps1 -Path .\GEMINI.md
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\signal-compress.ps1 -Path .\GEMINI.md -DryRun
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\signal-compress.ps1 -Path .\GEMINI.md -InvokeGemini
#
# Notes:
#   - -InvokeGemini is documented but *off by default*. Even when enabled, this
#     script only prints the command it would run; it never silently calls a
#     cloud API. You still copy-paste the prompt from
#     templates/signal-compress-prompt.md into the agent/CLI you trust.
#   - Gemini CLI users: API capacity errors (HTTP 429 / "No capacity available
#     for model ...") are common on free tiers. Retry or pass -Model to the CLI
#     manually. See benchmark/benchmark chess/README.md for background.

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path,

  [switch]$DryRun,

  [switch]$InvokeGemini,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$promptTemplate = Join-Path $repoRoot 'templates\signal-compress-prompt.md'
$docs = Join-Path $repoRoot 'docs\signal-compress.md'

function Write-Info([string]$Msg) { Write-Host $Msg -ForegroundColor Cyan }
function Write-Warn2([string]$Msg) { Write-Host $Msg -ForegroundColor Yellow }
function Write-Err2([string]$Msg) { Write-Host $Msg -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $Path)) {
  Write-Err2 "File not found: $Path"
  exit 1
}

$resolved = (Resolve-Path -LiteralPath $Path).Path
$leaf = Split-Path -Leaf $resolved
$dir = Split-Path -Parent $resolved

if ($leaf -match '\.original\.[A-Za-z0-9]+$') {
  Write-Err2 "Refusing to compress a backup file: $leaf"
  Write-Host "  Run against the compressed-target file, not the .original.* copy."
  exit 1
}

$ext = [System.IO.Path]::GetExtension($leaf)
$base = [System.IO.Path]::GetFileNameWithoutExtension($leaf)
$backupName = if ($ext) { "$base.original$ext" } else { "$base.original" }
$backupPath = Join-Path $dir $backupName

Write-Host ''
Write-Info 'signal-compress'
Write-Host "  target : $resolved"
Write-Host "  backup : $backupPath"
Write-Host "  prompt : $promptTemplate"
Write-Host "  docs   : $docs"
Write-Host ''

if (Test-Path -LiteralPath $backupPath) {
  if (-not $Force) {
    Write-Err2 "Backup already exists: $backupPath"
    Write-Host "  Use -Force to overwrite, or delete/rename the existing backup."
    exit 1
  }
  Write-Warn2 "-Force set: existing backup will be overwritten."
}

if ($DryRun) {
  Write-Warn2 'Dry run: no files were modified.'
  Write-Host 'Next steps (would have been):'
  Write-Host "  1. Copy-Item -LiteralPath '$resolved' -Destination '$backupPath'"
  Write-Host "  2. Open the prompt: $promptTemplate"
  Write-Host "  3. Paste $leaf into your agent with that prompt."
  Write-Host "  4. Replace the contents of $leaf with the agent's reply."
  Write-Host "  5. Diff $leaf against $backupName; revert if anything technical changed."
  if ($InvokeGemini) {
    Write-Host ''
    Write-Host '  (-InvokeGemini was set; this script does not call Gemini automatically.'
    Write-Host '   Suggested manual call once the backup exists:)'
    Write-Host "    gemini -p `"$promptTemplate`" -o json  # then paste file contents"
  }
  exit 0
}

Copy-Item -LiteralPath $resolved -Destination $backupPath -Force:$Force
Write-Info "Backup written: $backupPath"
Write-Host ''
Write-Host 'Next steps:'
Write-Host "  1. Open the prompt:    $promptTemplate"
Write-Host "  2. Run it against:     $resolved"
Write-Host '     (your host agent, or any LLM you trust; this script never calls one)'
Write-Host "  3. Save the reply over $leaf (keep the .original backup until reviewed)."
Write-Host "  4. Diff $leaf vs $backupName; revert on any technical drift."
Write-Host ''
Write-Host "Docs: $docs"

if ($InvokeGemini) {
  Write-Host ''
  Write-Warn2 '-InvokeGemini set: not auto-running. Suggested manual command:'
  Write-Host "  gemini -p `"$promptTemplate`" -o json"
  Write-Host '  (Free-tier Gemini can return HTTP 429 / "No capacity available for model ...";'
  Write-Host '   retry or pass -Model to the CLI.)'
}
