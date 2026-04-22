#Requires -Version 5.1
# Build ZIPs for manual "Upload skill" in Claude (web/desktop Customize) and for sharing.
# Run from repo root after sync-integration-packages.ps1 (or run that first).
# Output: assets/claude-skill-signal-minimal.zip, assets/claude-skill-signal-with-references.zip

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$assets = Join-Path $RepoRoot 'assets'
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('signal-zip-' + [Guid]::NewGuid().ToString('n'))

$minimal = Join-Path $RepoRoot 'claude-signal\skills\signal'
$kiroSkill = Join-Path $RepoRoot 'kiro-signal\skills\signal'
$kiroRefs = Join-Path $RepoRoot 'kiro-signal\references'

if (-not (Test-Path (Join-Path $minimal 'SKILL.md'))) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\sync-integration-packages.ps1')
}
if (-not (Test-Path (Join-Path $minimal 'SKILL.md'))) {
    throw "Missing claude-signal\skills\signal\SKILL.md. Run sync-integration-packages.ps1 from repo root."
}

New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
try {
    # 1) Folder "signal" at zip root (name must match frontmatter)
    $sigOut = Join-Path $workRoot 'signal'
    Copy-Item -LiteralPath $minimal -Destination $sigOut -Recurse -Force
    $zip1 = Join-Path $assets 'claude-skill-signal-minimal.zip'
    if (Test-Path $zip1) { Remove-Item -LiteralPath $zip1 -Force }
    Compress-Archive -Path $sigOut -DestinationPath $zip1 -Force
    Write-Host "Wrote $zip1"

    # 2) kiro-signal/ tree: skills/signal + references/ (../references links in SKILL resolve)
    if ((Test-Path $kiroSkill) -and (Test-Path $kiroRefs)) {
        $ks = Join-Path $workRoot 'kiro-signal\skills\signal'
        $kr = Join-Path $workRoot 'kiro-signal\references'
        New-Item -ItemType Directory -Path (Split-Path $ks -Parent) -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path $kr -Parent) -Force | Out-Null
        New-Item -ItemType Directory -Path $ks -Force | Out-Null
        New-Item -ItemType Directory -Path $kr -Force | Out-Null
        Copy-Item -Path (Join-Path $kiroSkill '*') -Destination $ks -Recurse -Force
        Copy-Item -Path (Join-Path $kiroRefs '*') -Destination $kr -Recurse -Force
        $zip2 = Join-Path $assets 'claude-skill-signal-with-references.zip'
        if (Test-Path $zip2) { Remove-Item -LiteralPath $zip2 -Force }
        $kiroBase = Join-Path $workRoot 'kiro-signal'
        Compress-Archive -Path $kiroBase -DestinationPath $zip2 -Force
        Write-Host "Wrote $zip2"
    } else {
        Write-Warning "Skipping with-references zip (kiro-signal not present or incomplete)."
    }
} finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "pack-skill-zips-for-upload: OK" -ForegroundColor Green
