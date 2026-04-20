#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$RequireGh,
  [switch]$StrictPr
)

<#
.SYNOPSIS
  Verification harness for SIGNAL v0.3.2

  Run from repo root:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1

  Exit code 0 = all checks passed; non-zero = failure.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$rootSkillsDir = Join-Path $RepoRoot 'skills'

if (-not (Test-Path $rootSkillsDir)) {
  Write-Host 'x Run this script from the SIGNAL repo (skills/ directory not found).'
  exit 1
}

$script:VerifyFailed = $false
function Fail([string]$msg) {
  Write-Host "x $msg" -ForegroundColor Red
  $script:VerifyFailed = $true
}

function Ok([string]$msg) {
  Write-Host "+ $msg" -ForegroundColor Green
}

# --- git on PATH ---
git --version *>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x git is required on PATH for script verification.'
  exit 1
}

# --- 0) Sync integration packages + structure ---
$syncPs1 = Join-Path $RepoRoot 'scripts\sync-integration-packages.ps1'
if (-not (Test-Path -LiteralPath $syncPs1)) {
  Fail "missing $syncPs1"
} else {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $syncPs1
  if ($LASTEXITCODE -ne 0) { Fail 'sync-integration-packages.ps1 failed'; exit 1 }
  Ok 'sync-integration-packages.ps1'
}

# Canonical root structure (v0.3.0)
$rootExt = Join-Path $RepoRoot 'gemini-extension.json'
$rootGem = Join-Path $RepoRoot 'GEMINI.md'
$rootSkill = Join-Path $RepoRoot 'skills\signal.md'
$rootMinSkill = Join-Path $RepoRoot 'skills\signal.min.md'
$rootBin = Join-Path $RepoRoot 'bin\run-commit.ps1'
foreach ($p in @($rootExt, $rootGem, $rootSkill, $rootMinSkill, $rootBin)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "repo-root incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'repo-root structure (v0.3.2)' }

# Extension mirroring structure
$geminiSkill = Join-Path $RepoRoot 'gemini-signal\skills\signal\SKILL.md'
$claudeSkill = Join-Path $RepoRoot 'claude-signal\skills\signal\SKILL.md'
$geminiMinSkill = Join-Path $RepoRoot 'gemini-signal\skills\signal\SKILL.min.md'
$claudeMinSkill = Join-Path $RepoRoot 'claude-signal\skills\signal\SKILL.min.md'

foreach ($p in @($geminiSkill, $claudeSkill, $geminiMinSkill, $claudeMinSkill)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "host extension incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'host extensions structure (v0.3.2 mirrored)' }

# Kiro mirror structure
$kiroSkill    = Join-Path $RepoRoot 'kiro-signal\skills\signal\SKILL.md'
$kiroMinSkill = Join-Path $RepoRoot 'kiro-signal\skills\signal\SKILL.min.md'
$kiroRefs     = Join-Path $RepoRoot 'kiro-signal\references\symbols.md'

foreach ($p in @($kiroSkill, $kiroMinSkill, $kiroRefs)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "kiro extension incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'kiro-signal structure (v0.3.2 mirrored)' }

# --- 0b) bin/run-commit.ps1 --dry ---
$commitWrapper = Join-Path $RepoRoot 'bin\run-commit.ps1'
if (-not (Test-Path -LiteralPath $commitWrapper)) {
  Fail "missing $commitWrapper"
} else {
  $tmpG = Join-Path ([System.IO.Path]::GetTempPath()) ("signal-verify-commit-" + [Guid]::NewGuid().ToString('n'))
  try {
    New-Item -ItemType Directory -Path $tmpG -Force | Out-Null
    Push-Location $tmpG
    git init -q
    git config user.email 'verify@local'
    git config user.name 'verify'
    Set-Content -Path 'hello.txt' -Value 'test'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $commitWrapper --dry -- 'chore(verify): root wrapper dry'
    if ($LASTEXITCODE -ne 0) { Fail 'bin/run-commit.ps1 --dry failed' } else { Ok 'bin/run-commit.ps1 --dry (temp repo)' }
  } finally {
    Pop-Location
    Remove-Item -LiteralPath $tmpG -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- 4) Markdown relative link targets ---
$mdFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\benchmark\\' -and
    $_.FullName -notmatch '\\gemini-signal\\skills\\' -and
    $_.FullName -notmatch '\\claude-signal\\skills\\' -and
    $_.FullName -notmatch '\\kiro-signal\\skills\\'
  }

$linkPattern = '\[[^\]]*\]\(([^)]+)\)'
$badLinks = [System.Collections.ArrayList]::new()

foreach ($md in $mdFiles) {
  $dir = Split-Path $md.FullName -Parent
  $text = Get-Content -LiteralPath $md.FullName -Raw -ErrorAction SilentlyContinue
  if (-not $text) { continue }
  foreach ($m in [regex]::Matches($text, $linkPattern)) {
    $raw = $m.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }
    if ($raw -match '^(https?|mailto):') { continue }
    $pathPart = ($raw -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($pathPart)) { continue }
    $pathPart = $pathPart.Trim()
    if ($pathPart.StartsWith('<') -and $pathPart.EndsWith('>')) {
      $pathPart = $pathPart.Substring(1, $pathPart.Length - 2).Trim()
    }
    try {
      $pathPart = [uri]::UnescapeDataString($pathPart)
    } catch { }
    if ($pathPart.StartsWith('/')) { continue }
    $resolved = Join-Path $dir $pathPart
    try {
      $canon = [System.IO.Path]::GetFullPath($resolved)
    } catch {
      [void]$badLinks.Add("$($md.Name) -> $raw (invalid path)")
      continue
    }
    if (-not (Test-Path -LiteralPath $canon)) {
      [void]$badLinks.Add("$($md.FullName.Replace($RepoRoot + '\', '')) -> $raw")
    }
  }
}

if ($badLinks.Count -gt 0) {
  foreach ($b in $badLinks) { Fail "broken link: $b" }
} else {
  Ok ("markdown relative links ({0} files scanned)" -f @($mdFiles).Count)
}

if ($script:VerifyFailed) {
  Write-Host "`nx One or more checks failed." -ForegroundColor Red
  exit 1
}
Write-Host "`n+ All required checks passed (v0.3.2)." -ForegroundColor Green
exit 0
