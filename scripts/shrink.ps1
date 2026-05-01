#Requires -Version 5.1
# SIGNAL v0.4.0 - shrink.ps1
# Checks canonical SKILL.md / SKILL.min.md pairs and reports shrink ratios.

[CmdletBinding()]
param(
    [string]$Path,
    [switch]$All,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

function Shrink-File([string]$target) {
    $minPath = $target.Replace(".md", ".min.md")
    Write-Host "Shrinking $target -> $minPath" -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "  [DryRun] Would shrink $target"
        return
    }
    
    if (-not (Test-Path -LiteralPath $minPath)) {
        Write-Host "  x Missing $minPath. Please create it using Symbol Grammar." -ForegroundColor Red
        $script:ShrinkFailed = $true
        return
    }

    $origSize = (Get-Item -LiteralPath $target).Length
    $minSize = (Get-Item -LiteralPath $minPath).Length
    
    if ($origSize -eq 0) {
        $ratio = 0
    } else {
        $ratio = [math]::Round((1 - ($minSize / $origSize)) * 100, 1)
    }

    Write-Host "  OK. Shrink ratio: $ratio % ($origSize bytes -> $minSize bytes)" -ForegroundColor Green
}

if ($All) {
    $script:ShrinkFailed = $false
    # Only check top-level skills directory for canonical v0.4.0 pairs.
    Get-ChildItem -Path "$repoRoot\skills" -Filter "*.md" | Where-Object { $_.Name -notmatch "\.min\.md$" -and $_.Name -ne "signal-core.min.md" } | ForEach-Object {
        Shrink-File $_.FullName
    }
    if ($script:ShrinkFailed) { exit 1 }
} elseif ($Path) {
    $script:ShrinkFailed = $false
    Shrink-File (Resolve-Path -LiteralPath $Path).Path
    if ($script:ShrinkFailed) { exit 1 }
} else {
    Write-Host "Please provide -Path or use -All" -ForegroundColor Red
    exit 1
}
