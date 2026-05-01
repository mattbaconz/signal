#Requires -Version 5.1
# SIGNAL v0.4.0 - sync-integration-packages.ps1
# Source of truth: root skills/ directory.
# Mirrors canonical skills into gemini-signal/skills, claude-signal/skills, and kiro-signal/skills.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$rootSkillsDir = Join-Path $RepoRoot 'skills'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $rootSkillsDir)) {
    Write-Error "Run from SIGNAL repo root (skills\ directory not found)."
    exit 1
}

# 1. Ensure all .min.md are up to date
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'shrink.ps1') -All
if ($LASTEXITCODE -ne 0) { Write-Error "shrink.ps1 failed"; exit 1 }

$targets = @(
    (Join-Path $RepoRoot 'gemini-signal\skills'),
    (Join-Path $RepoRoot 'claude-signal\skills'),
    (Join-Path $RepoRoot 'kiro-signal\skills')
)

foreach ($destRoot in $targets) {
    if (Test-Path $destRoot) {
        Remove-Item -LiteralPath $destRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
    
    # Mirror individual files from skills/ into their own folders in the extensions.
    # This maintains the /signal-commit/SKILL.md structure for host compatibility.
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

    # Mirror per-skill helper scripts. The skill specs and bin wrappers reference
    # these paths directly, so packaged host trees must include them.
    Get-ChildItem -Path $rootSkillsDir -Directory | ForEach-Object {
        $scriptSrc = Join-Path $_.FullName 'scripts'
        if (-not (Test-Path -LiteralPath $scriptSrc)) { return }
        $scriptDst = Join-Path (Join-Path $destRoot $_.Name) 'scripts'
        New-Item -ItemType Directory -Path $scriptDst -Force | Out-Null
        Copy-Item -Path (Join-Path $scriptSrc '*') -Destination $scriptDst -Recurse -Force
        Write-Host "  synced $($_.Name)\scripts -> $scriptDst"
    }
}

# 2. Kiro: bundle references/ alongside skills/ so imported skill folders resolve protocol links.
# Kiro imports are GitHub subtree URLs (one skill folder at a time), but links in SKILL.md
# point to ../../references/ which resolves to kiro-signal/references/ in context.
$kiroSkillsDir = Join-Path $RepoRoot 'kiro-signal\skills'
$kiroRefsDir   = Join-Path $RepoRoot 'kiro-signal\references'
$rootRefsDir   = Join-Path $RepoRoot 'references'

if (Test-Path $kiroRefsDir) { Remove-Item -LiteralPath $kiroRefsDir -Recurse -Force }
New-Item -ItemType Directory -Path $kiroRefsDir -Force | Out-Null
& robocopy.exe $rootRefsDir $kiroRefsDir /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy references to kiro-signal failed: $LASTEXITCODE"; exit 1 }
Write-Host "  synced references/ -> kiro-signal/references/"

# Rewrite ../references/ links in kiro-signal skill files to ../../references/
# (skill lives at kiro-signal/skills/<name>/SKILL.md, references at kiro-signal/references/)
Get-ChildItem -Path $kiroSkillsDir -Recurse -Filter "*.md" | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $rewritten = $content.Replace('(../references/', '(../../references/')
    if ($rewritten -ne $content) {
        [System.IO.File]::WriteAllText($_.FullName, $rewritten, $Utf8NoBom)
        Write-Host "  rewrote references links: $($_.FullName)"
    }
}

# 3. Sync root manifests and binaries (Gemini-specific)
$geminiPack = Join-Path $RepoRoot 'gemini-signal'

# Root Gemini extension (gallery + gemini extensions install <github-url>)
Copy-Item -LiteralPath (Join-Path $geminiPack 'gemini-extension.json') -Destination (Join-Path $RepoRoot 'gemini-extension.json') -Force

# Root GEMINI.md: same content as gemini-signal/GEMINI.md but paths are repo-root-relative (no ../).
$geminiSrc = Join-Path $geminiPack 'GEMINI.md'
$geminiDst = Join-Path $RepoRoot 'GEMINI.md'
$geminiBody = [System.IO.File]::ReadAllText($geminiSrc, [System.Text.Encoding]::UTF8)
$geminiBody = $geminiBody.Replace('../skills/', 'skills/').Replace('../references/', 'references/')
[System.IO.File]::WriteAllText($geminiDst, $geminiBody, $Utf8NoBom)

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

Write-Host "sync-integration-packages: OK (v0.4.0 logic)" -ForegroundColor Green
exit 0
