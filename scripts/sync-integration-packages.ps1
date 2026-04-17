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

function Set-SignalSkillReadmeLink {
  param(
    [Parameter(Mandatory = $true)][string]$SkillMdPath,
    [Parameter(Mandatory = $true)][ValidateRange(2, 5)][int]$ParentLevelsToRepoRoot
  )
  if (-not (Test-Path -LiteralPath $SkillMdPath)) { return }
  $prefix = '../' * $ParentLevelsToRepoRoot
  $oldLink = '[`' + '../README.md' + '`' + '](../README.md)'
  $newLink = '[`' + $prefix + 'README.md' + '`](' + $prefix + 'README.md)'
  $raw = Get-Content -LiteralPath $SkillMdPath -Raw -Encoding utf8
  if (-not $raw.Contains($oldLink)) { return }
  Set-Content -LiteralPath $SkillMdPath -Value ($raw.Replace($oldLink, $newLink)) -Encoding utf8
}

# --- Gemini extension at repository root (gallery + `gemini extensions install <github-url>`) ---
# See https://geminicli.com/docs/extensions/releasing — indexer expects gemini-extension.json at Git root.
$geminiPack = Join-Path $RepoRoot 'gemini-signal'
$extJson = Join-Path $geminiPack 'gemini-extension.json'
$extGem = Join-Path $geminiPack 'GEMINI.md'
if (-not (Test-Path -LiteralPath $extJson)) {
  Write-Error "Missing $extJson"
  exit 1
}
Copy-Item -LiteralPath $extJson -Destination (Join-Path $RepoRoot 'gemini-extension.json') -Force
Copy-Item -LiteralPath $extGem -Destination (Join-Path $RepoRoot 'GEMINI.md') -Force
& robocopy.exe (Join-Path $geminiPack 'skills') (Join-Path $RepoRoot 'skills') /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy skills -> repo root failed: $LASTEXITCODE"; exit 1 }
& robocopy.exe (Join-Path $geminiPack 'commands') (Join-Path $RepoRoot 'commands') /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy commands -> repo root failed: $LASTEXITCODE"; exit 1 }
& robocopy.exe (Join-Path $geminiPack 'bin') (Join-Path $RepoRoot 'bin') /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy bin -> repo root failed: $LASTEXITCODE"; exit 1 }

# Mirrored signal/SKILL.md: ../README.md only works from signal/; deeper paths need extra .. segments.
$signalSkillMirrors = @(
  @{ Path = (Join-Path $RepoRoot 'skills\signal\SKILL.md'); Levels = 2 },
  @{ Path = (Join-Path $RepoRoot 'gemini-signal\skills\signal\SKILL.md'); Levels = 3 },
  @{ Path = (Join-Path $RepoRoot 'claude-signal\skills\signal\SKILL.md'); Levels = 3 }
)
foreach ($m in $signalSkillMirrors) {
  Set-SignalSkillReadmeLink -SkillMdPath $m.Path -ParentLevelsToRepoRoot $m.Levels
}

Write-Host "sync-integration-packages: OK" -ForegroundColor Green
exit 0
