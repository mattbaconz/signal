# Copy all SIGNAL skills from this repo into standard user-level agent skill folders.
# Source: claude-signal/skills/<name>/ (mirrored SKILL.md layout). Run after clone; optional: run sync-integration-packages.ps1 first.
# Uses Copy-Item (no symlinks) so Windows works without Developer Mode elevation.
# Run:  powershell -ExecutionPolicy Bypass -File .\scripts\install-signal-all.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$skillSrcRoot = Join-Path $repoRoot "claude-signal\skills"

if (-not (Test-Path (Join-Path $skillSrcRoot "signal\SKILL.md"))) {
  throw "Could not find $skillSrcRoot\signal\SKILL.md. Clone the SIGNAL repo and run sync-integration-packages.ps1 if mirrors are missing."
}

# Avoid duplicate skill paths: installing the same skill under multiple agent roots can trigger "Skill conflict" warnings.
# This script targets separate trees per host; only ~/.claude/skills/ is required for Claude Code standalone install.
$targets = @(
  @{ Path = Join-Path $env:USERPROFILE ".agents\skills";          Name = "Universal .agents (Gemini + others)" },
  @{ Path = Join-Path $env:USERPROFILE ".claude\skills";          Name = "Claude Code" },
  @{ Path = Join-Path $env:USERPROFILE ".cursor\skills";          Name = "Cursor" },
  @{ Path = Join-Path $env:USERPROFILE ".codex\skills";           Name = "OpenAI Codex" }
)

Get-ChildItem -Path $skillSrcRoot -Directory | ForEach-Object {
  $folderName = $_.Name
  foreach ($t in $targets) {
    $destRoot = $t.Path
    if (-not (Test-Path $destRoot)) {
      New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
    }
    $src = $_.FullName
    $dst = Join-Path $destRoot $folderName
    Write-Host "=== $($t.Name)  $folderName -> $dst" -ForegroundColor Cyan
    if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
  }
}

Write-Host "`nDone. Skills copied to: $(($targets | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor Green
Write-Host "  Claude Code: use slash commands like /signal, /signal-commit (no plugin namespace)." -ForegroundColor Green
Write-Host "  Do not also install the SIGNAL plugin if you use this standalone copy (duplicate definitions)." -ForegroundColor Yellow
Write-Host "  Gemini CLI:  copy templates\gemini-GEMINI.md into a project as GEMINI.md (merge with your rules)." -ForegroundColor Green
Write-Host "  Claude Code: copy templates\claude-CLAUDE.md into a project as CLAUDE.md (merge with your rules)." -ForegroundColor Green
