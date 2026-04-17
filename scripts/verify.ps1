#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$RequireGh,
  [switch]$StrictPr
)

<#
.SYNOPSIS
  Verification harness for SIGNAL: sync integration packages, Windows scripts (--dry), optional gh, and markdown link targets.

  Run from repo root:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireGh -StrictPr

  Exit code 0 = all checks passed; non-zero = failure.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $RepoRoot 'signal\SKILL.md'))) {
  Write-Host 'x Run this script from the singal-skill repo (signal\SKILL.md not found).'
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

$geminiExt = Join-Path $RepoRoot 'gemini-signal\gemini-extension.json'
$geminiGem = Join-Path $RepoRoot 'gemini-signal\GEMINI.md'
$geminiSkill = Join-Path $RepoRoot 'gemini-signal\skills\signal\SKILL.md'
$geminiBin = Join-Path $RepoRoot 'gemini-signal\bin\run-commit.ps1'
foreach ($p in @($geminiExt, $geminiGem, $geminiSkill, $geminiBin)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "gemini-signal incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'gemini-signal structure' }

# Root-level Gemini extension mirror (gallery expects gemini-extension.json at Git root)
$rootExt = Join-Path $RepoRoot 'gemini-extension.json'
$rootGem = Join-Path $RepoRoot 'GEMINI.md'
$rootSkill = Join-Path $RepoRoot 'skills\signal\SKILL.md'
$rootBin = Join-Path $RepoRoot 'bin\run-commit.ps1'
foreach ($p in @($rootExt, $rootGem, $rootSkill, $rootBin)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "repo-root Gemini extension incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'repo-root Gemini extension (gallery layout)' }

$claudePlug = Join-Path $RepoRoot 'claude-signal\.claude-plugin\plugin.json'
$claudeSkill = Join-Path $RepoRoot 'claude-signal\skills\signal\SKILL.md'
foreach ($p in @($claudePlug, $claudeSkill)) {
  if (-not (Test-Path -LiteralPath $p)) { Fail "claude-signal incomplete: missing $p" }
}
if (-not $script:VerifyFailed) { Ok 'claude-signal structure' }

$mkt = Join-Path $RepoRoot '.claude-plugin\marketplace.json'
if (-not (Test-Path -LiteralPath $mkt)) { Fail "missing $mkt" } else { Ok '.claude-plugin/marketplace.json' }

# --- 0a) Host IDE rules (Cursor, Windsurf, Cline, Copilot) from templates/host-always-on.body.md
$hostSync = Join-Path $RepoRoot 'scripts\sync-host-integrations.ps1'
if (-not (Test-Path -LiteralPath $hostSync)) {
  Fail "missing $hostSync"
} else {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $hostSync
  if ($LASTEXITCODE -ne 0) { Fail 'sync-host-integrations.ps1 failed'; exit 1 }
  Ok 'sync-host-integrations.ps1'
}
$canonSnippet = 'SIGNAL-1'
$hostFiles = @(
  (Join-Path $RepoRoot '.cursor\rules\signal.mdc'),
  (Join-Path $RepoRoot '.windsurf\rules\signal.md'),
  (Join-Path $RepoRoot '.clinerules\signal.md'),
  (Join-Path $RepoRoot '.github\copilot-instructions.md')
)
foreach ($hf in $hostFiles) {
  if (-not (Test-Path -LiteralPath $hf)) { Fail "host integration missing: $hf" }
  $htxt = Get-Content -LiteralPath $hf -Raw
  if ($htxt -notmatch [regex]::Escape($canonSnippet)) { Fail "host file missing canon marker ($canonSnippet): $hf" }
}
if (-not $script:VerifyFailed) { Ok 'host IDE rules (synced + spot-check)' }

# --- 0b) gemini-signal/bin/run-commit.ps1 --dry (uses bundled skill copy) ---
$geminiCommitWrapper = Join-Path $RepoRoot 'gemini-signal\bin\run-commit.ps1'
if (-not (Test-Path -LiteralPath $geminiCommitWrapper)) {
  Fail "missing $geminiCommitWrapper"
} else {
  $tmpG = Join-Path ([System.IO.Path]::GetTempPath()) ("signal-verify-gemini-commit-" + [Guid]::NewGuid().ToString('n'))
  try {
    New-Item -ItemType Directory -Path $tmpG -Force | Out-Null
    Push-Location $tmpG
    git init -q
    git config user.email 'verify@local'
    git config user.name 'verify'
    Set-Content -Path 'hello.txt' -Value 'test'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $geminiCommitWrapper --dry -- 'chore(verify): gemini wrapper dry'
    if ($LASTEXITCODE -ne 0) { Fail 'gemini-signal/bin/run-commit.ps1 --dry failed' } else { Ok 'gemini-signal/bin/run-commit.ps1 --dry (temp repo)' }
  } finally {
    Pop-Location
    Remove-Item -LiteralPath $tmpG -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- 1) commit.ps1 --dry ---
$commitPs1 = Join-Path $RepoRoot 'signal-commit\scripts\commit.ps1'
if (-not (Test-Path -LiteralPath $commitPs1)) {
  Fail "missing $commitPs1"
} else {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("signal-verify-commit-" + [Guid]::NewGuid().ToString('n'))
  try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Push-Location $tmp
    git init -q
    git config user.email 'verify@local'
    git config user.name 'verify'
    Set-Content -Path 'hello.txt' -Value 'test'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $commitPs1 --dry -- 'chore(verify): dry run'
    if ($LASTEXITCODE -ne 0) { Fail 'commit.ps1 --dry failed' } else { Ok 'commit.ps1 --dry (temp repo)' }
  } finally {
    Pop-Location
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- 2) push.ps1 --dry (needs origin) ---
$pushPs1 = Join-Path $RepoRoot 'signal-push\scripts\push.ps1'
if (-not (Test-Path -LiteralPath $pushPs1)) {
  Fail "missing $pushPs1"
} else {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("signal-verify-push-" + [Guid]::NewGuid().ToString('n'))
  try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Push-Location $tmp
    git init -q
    git config user.email 'verify@local'
    git config user.name 'verify'
    git remote add origin 'https://example.invalid/signal-verify.git'
    Set-Content -Path 'hello.txt' -Value 'test'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $pushPs1 --dry -- 'chore(verify): push dry'
    if ($LASTEXITCODE -ne 0) { Fail 'push.ps1 --dry failed' } else { Ok 'push.ps1 --dry (temp repo + origin)' }
  } finally {
    Pop-Location
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- 3) pr.ps1 --dry (optional: gh) ---
$prPs1 = Join-Path $RepoRoot 'signal-pr\scripts\pr.ps1'
if (-not (Test-Path -LiteralPath $prPs1)) {
  Fail "missing $prPs1"
} elseif (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  if ($RequireGh -or $StrictPr) {
    Fail 'gh required but not found on PATH'
  } else {
    Write-Host '? pr.ps1 --dry skipped (gh not on PATH)' -ForegroundColor Yellow
  }
} else {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("signal-verify-pr-" + [Guid]::NewGuid().ToString('n'))
  try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Push-Location $tmp
    git init -q
    git config user.email 'verify@local'
    git config user.name 'verify'
    git remote add origin 'https://example.invalid/signal-verify.git'
    Set-Content -Path 'hello.txt' -Value 'test'
    $ErrorActionPreference = 'Continue'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $prPs1 --dry -- 'chore(verify): pr dry'
    $exitPr = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($exitPr -ne 0) {
      if ($StrictPr) {
        Fail 'pr.ps1 --dry failed under strict gh verification'
      } else {
        Write-Host '? pr.ps1 --dry non-zero (often gh auth / no GitHub repo) - check manually' -ForegroundColor Yellow
      }
    } else {
      Ok 'pr.ps1 --dry'
    }
  } finally {
    Pop-Location
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# --- 4) Markdown relative link targets ---
$mdFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\benchmark\\' -and
    $_.FullName -notmatch '\\gemini-signal\\skills\\' -and
    $_.FullName -notmatch '\\claude-signal\\skills\\'
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
Write-Host "`n+ All required checks passed." -ForegroundColor Green
exit 0
