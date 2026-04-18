#Requires -Version 5.1
# SIGNAL v0.3.0 - sync-integration-packages.ps1
# Source of truth: root skills/ directory.
# Mirrors canonical skills into gemini-signal/skills and claude-signal/skills.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$rootSkillsDir = Join-Path $RepoRoot 'skills'

if (-not (Test-Path $rootSkillsDir)) {
    Write-Error "Run from SIGNAL repo root (skills\ directory not found)."
    exit 1
}

# 1. Ensure all .min.md are up to date
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'shrink.ps1') -All
if ($LASTEXITCODE -ne 0) { Write-Error "shrink.ps1 failed"; exit 1 }

$targets = @(
    (Join-Path $RepoRoot 'gemini-signal\skills'),
    (Join-Path $RepoRoot 'claude-signal\skills')
)

foreach ($destRoot in $targets) {
    if (Test-Path $destRoot) {
        Remove-Item -LiteralPath $destRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
    
    # Mirror individual files from skills/ into their own folders in the extensions
    # This maintains the /signal-commit/SKILL.md structure for host compatibility
    Get-ChildItem -Path $rootSkillsDir -Filter "*.md" | ForEach-Object {
        $baseName = $_.BaseName.Replace(".min", "")
        $targetDir = Join-Path $destRoot $baseName
        
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Determine if this is a .min.md or .md
        $isMin = $_.Name.EndsWith(".min.md")
        $destName = if ($isMin) { "SKILL.min.md" } else { "SKILL.md" }
        
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetDir $destName) -Force
        Write-Host "  synced $($_.Name) -> $targetDir\$destName"
    }
}

# 2. Sync root manifests and binaries
$geminiPack = Join-Path $RepoRoot 'gemini-signal'

# Root Gemini extension (gallery + gemini extensions install <github-url>)
Copy-Item -LiteralPath (Join-Path $geminiPack 'gemini-extension.json') -Destination (Join-Path $RepoRoot 'gemini-extension.json') -Force
Copy-Item -LiteralPath (Join-Path $geminiPack 'GEMINI.md') -Destination (Join-Path $RepoRoot 'GEMINI.md') -Force

# Robocopy for directories
$syncDirs = @('commands', 'bin')
foreach ($dir in $syncDirs) {
    $src = Join-Path $geminiPack $dir
    $dst = Join-Path $RepoRoot $dir
    if (Test-Path $src) {
        if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
        & robocopy.exe $src $dst /E /NFL /NDL /NJH /NJS /PURGE
        if ($LASTEXITCODE -ge 8) { Write-Error "robocopy $dir failed: $LASTEXITCODE"; exit 1 }
    }
}

Write-Host "sync-integration-packages: OK (v0.3.0 logic)" -ForegroundColor Green
exit 0
