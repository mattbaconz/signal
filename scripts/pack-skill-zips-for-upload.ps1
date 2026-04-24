#Requires -Version 5.1
# Build ZIPs for manual "Upload skill" in Claude (web/desktop Customize).
# Windows Compress-Archive writes '\' in entry names; strict uploaders error with
# "Zip file contains path with invalid characters". This script uses `tar -a` (ZIP)
# so paths use '/' per the archive format.
# Some uploader (Claude desktop) rejects SKILL.md with a UTF-8 BOM: the file must
# begin with the bytes for `---`, not U+FEFF. After staging copies, all *.md are
# stripped of a leading EF BB BF if present.
# Run from repo root. Output under assets/:
#   claude-skill-signal-minimal.zip, claude-skill-signal-flat.zip,
#   claude-skill-signal-with-references.zip

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$assets = Join-Path $RepoRoot 'assets'
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('signal-zip-' + [Guid]::NewGuid().ToString('n'))
$tar = (Get-Command tar.exe -ErrorAction SilentlyContinue)
if (-not $tar) { throw "tar.exe not on PATH. Windows 10+ includes bsdtar as tar." }

function Remove-Utf8BomFromMarkdownTree {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) { return }
    Get-ChildItem -LiteralPath $Root -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        $b = [IO.File]::ReadAllBytes($p)
        if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
            [IO.File]::WriteAllBytes($p, $b[3..($b.Length - 1)])
        }
    }
}

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
    # 1) signal/ folder
    $sigOut = Join-Path $workRoot 'signal'
    Copy-Item -LiteralPath $minimal -Destination $sigOut -Recurse -Force
    Remove-Utf8BomFromMarkdownTree -Root $sigOut
    $zip1 = Join-Path $assets 'claude-skill-signal-minimal.zip'
    if (Test-Path -LiteralPath $zip1) { Remove-Item -LiteralPath $zip1 -Force }
    Push-Location $workRoot
    try {
        & tar.exe -a -c -f $zip1 "signal"
    } finally { Pop-Location }
    Write-Host "Wrote $zip1"

    # 2) flat: SKILL.md and SKILL.min.md at zip root
    $zipFlat = Join-Path $assets 'claude-skill-signal-flat.zip'
    if (Test-Path -LiteralPath $zipFlat) { Remove-Item -LiteralPath $zipFlat -Force }
    $flat = Join-Path $workRoot 'flat'
    New-Item -ItemType Directory -Path $flat -Force | Out-Null
    Copy-Item (Join-Path $minimal 'SKILL.md') (Join-Path $flat 'SKILL.md') -Force
    if (Test-Path (Join-Path $minimal 'SKILL.min.md')) {
        Copy-Item (Join-Path $minimal 'SKILL.min.md') (Join-Path $flat 'SKILL.min.md') -Force
    }
    Remove-Utf8BomFromMarkdownTree -Root $flat
    Push-Location $flat
    try {
        if (Test-Path 'SKILL.min.md') {
            & tar.exe -a -c -f $zipFlat "SKILL.md" "SKILL.min.md"
        } else {
            & tar.exe -a -c -f $zipFlat "SKILL.md"
        }
    } finally { Pop-Location }
    Write-Host "Wrote $zipFlat"

    # 3) kiro-signal/ tree
    if ((Test-Path $kiroSkill) -and (Test-Path $kiroRefs)) {
        $kiroOut = Join-Path $workRoot 'kiro-signal\skills\signal'
        $kref = Join-Path $workRoot 'kiro-signal\references'
        New-Item -ItemType Directory -Path (Split-Path $kiroOut -Parent) -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path $kref -Parent) -Force | Out-Null
        New-Item -ItemType Directory -Path $kiroOut -Force | Out-Null
        New-Item -ItemType Directory -Path $kref -Force | Out-Null
        Copy-Item -Path (Join-Path $kiroSkill '*') -Destination $kiroOut -Recurse -Force
        Copy-Item -Path (Join-Path $kiroRefs '*') -Destination $kref -Recurse -Force
        Remove-Utf8BomFromMarkdownTree -Root (Join-Path $workRoot 'kiro-signal')
        $zip3 = Join-Path $assets 'claude-skill-signal-with-references.zip'
        if (Test-Path -LiteralPath $zip3) { Remove-Item -LiteralPath $zip3 -Force }
        $kbase = Join-Path $workRoot 'kiro-signal'
        Push-Location $workRoot
        try {
            & tar.exe -a -c -f $zip3 "kiro-signal"
        } finally { Pop-Location }
        Write-Host "Wrote $zip3"
    } else {
        Write-Warning "Skipping with-references zip (kiro-signal not present or incomplete)."
    }
} finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "pack-skill-zips-for-upload: OK" -ForegroundColor Green
