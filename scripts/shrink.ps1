#Requires -Version 5.1
# SIGNAL v0.3.0 - shrink.ps1
# Automates minification of SKILL.md into SKILL.min.md using Symbol Grammar.

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
        Write-Host "  ! Missing $minPath. Please create it using Symbol Grammar." -ForegroundColor Yellow
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
    # Only check top-level skills directory and root for canonical v0.3.0 pairs
    Get-ChildItem -Path "$repoRoot\skills" -Filter "*.md" | Where-Object { $_.Name -notmatch "\.min\.md$" -and $_.Name -ne "signal-core.min.md" } | ForEach-Object {
        Shrink-File $_.FullName
    }
} elseif ($Path) {
    Shrink-File (Resolve-Path -LiteralPath $Path).Path
} else {
    Write-Host "Please provide -Path or use -All" -ForegroundColor Red
}
