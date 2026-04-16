# Copy all SIGNAL skills from this repo into standard user-level agent skill folders.
# Uses Copy-Item (no symlinks) so Windows works without Developer Mode elevation.
# Run:  powershell -ExecutionPolicy Bypass -File .\scripts\install-signal-all.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $repoRoot "signal\SKILL.md"))) {
  throw "Could not find repo root containing signal\SKILL.md. Run from singal-skill clone."
}

$skillDirs = @("signal", "signal-commit", "signal-push", "signal-pr", "signal-review", "signal-ckpt")
# Avoid duplicate skill paths: Gemini CLI (and related tools) can load more than one discovery root.
# Installing the same skill under ~/.gemini/skills/, ~/.agents/skills/, AND ~/.gemini/antigravity/skills/
# triggers "Skill conflict" warnings. This script uses a single shared tree:
#   ~/.agents/skills/  — discovered by Gemini CLI and other agents (see agentskills.io / Gemini docs).
# Do not add .gemini\skills or .gemini\antigravity\skills here. Antigravity-only: copy manually or symlink.
$targets = @(
  @{ Path = Join-Path $env:USERPROFILE ".agents\skills";          Name = "Universal .agents (Gemini + others)" },
  @{ Path = Join-Path $env:USERPROFILE ".claude\skills";          Name = "Claude Code" },
  @{ Path = Join-Path $env:USERPROFILE ".cursor\skills";          Name = "Cursor" },
  @{ Path = Join-Path $env:USERPROFILE ".codex\skills";           Name = "OpenAI Codex" }
)

foreach ($t in $targets) {
  $destRoot = $t.Path
  if (-not (Test-Path $destRoot)) {
    New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
  }
  Write-Host "=== $($t.Name) -> $destRoot" -ForegroundColor Cyan
  foreach ($name in $skillDirs) {
    $src = Join-Path $repoRoot $name
    $dst = Join-Path $destRoot $name
    if (-not (Test-Path $src)) { Write-Warning "Skip missing: $src"; continue }
    if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    Write-Host "  copied $name"
  }
}

Write-Host "`nDone." -ForegroundColor Green
Write-Host "  Gemini CLI:  copy templates\gemini-GEMINI.md into a project as GEMINI.md (merge with your rules)." -ForegroundColor Green
Write-Host "  Claude Code: copy templates\claude-CLAUDE.md into a project as CLAUDE.md (merge with your rules)." -ForegroundColor Green
