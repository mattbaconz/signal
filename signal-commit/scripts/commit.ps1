#Requires -Version 5.1
<#
.SYNOPSIS
  Git mechanics for /signal-commit (Windows-native). Mirrors commit.sh.
  The agent supplies the conventional commit message; this script stages, commits, optional push.

  Usage:
    .\commit.ps1 [--draft] [--split] [--push] [--dry] [--] "commit message"
    echo "msg" | .\commit.ps1   # when stdin is piped (non-interactive)
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-GitRepo {
  git rev-parse --git-dir 2>$null | Out-Null
  return $LASTEXITCODE -eq 0
}

function Get-ConflictMarkerFiles {
  $text = (& git diff --check 2>&1 | Out-String).TrimEnd()
  if (-not $text) { return @() }
  $paths = New-Object System.Collections.Generic.HashSet[string]
  foreach ($line in ($text -split "`r?`n")) {
    if (-not $line) { continue }
    if ($line -match 'leftover conflict marker' -and $line -match '^([^:]+):') {
      [void]$paths.Add($Matches[1].Trim())
    }
  }
  if ($paths.Count -eq 0) { return @() }
  return @($paths.ToArray())
}

function Get-AllChangedFiles {
  # Pipeline preserves one-line-per-file; avoids string concatenation when using + on scalars.
  $staged = @(git diff --staged --name-only 2>$null | ForEach-Object { $_ })
  $unstaged = @(git diff --name-only 2>$null | ForEach-Object { $_ })
  $untracked = @(git ls-files --others --exclude-standard 2>$null | ForEach-Object { $_ })
  $all = @(@($staged) + @($unstaged) + @($untracked) | Where-Object { $_ } | Sort-Object -Unique)
  return $all
}

function Get-Stats {
  $diffStat = @(git diff --staged --numstat 2>$null)
  $added = 0
  $removed = 0
  foreach ($line in $diffStat) {
    if (-not $line) { continue }
    $parts = $line -split "`t", 3
    if ($parts.Count -lt 2) { continue }
    if ($parts[0] -ne '-') { $added += [int]$parts[0] }
    if ($parts[1] -ne '-') { $removed += [int]$parts[1] }
  }
  return "+${added}/-${removed}"
}

function Normalize-Message([string]$msg) {
  if ($msg.Length -le 72) { return $msg }
  Write-Host "? message exceeds 72 chars ($($msg.Length)) - truncating description" -ForegroundColor Yellow
  $needle = ': '
  $idx = $msg.IndexOf($needle)
  if ($idx -lt 0) {
    return $msg.Substring(0, [Math]::Min(72, $msg.Length))
  }
  $prefix = $msg.Substring(0, $idx + $needle.Length)
  $desc = $msg.Substring($idx + $needle.Length)
  $maxDesc = 72 - $prefix.Length
  if ($maxDesc -lt 1) { return $msg.Substring(0, 72) }
  $take = [Math]::Min($maxDesc, $desc.Length)
  return $prefix + $desc.Substring(0, $take)
}

function Get-ScopeFromMessage([string]$commitMsg) {
  if ($commitMsg -match '^\w+\(([^)]+)\):') { return $Matches[1] }
  return $null
}

# ── Flag parsing ──────────────────────────────────────────────────────────────
$Draft = $false
$Split = $false
$Push = $false
$Dry = $false
$Msg = $null
$argv = @($args)
$i = 0
while ($i -lt $argv.Count) {
  switch ($argv[$i]) {
    '--draft' { $Draft = $true; $i++; continue }
    '--split' { $Split = $true; $i++; continue }
    '--push'  { $Push = $true;  $i++; continue }
    '--dry'   { $Dry = $true;   $i++; continue }
    '--' {
      $i++
      if ($i -lt $argv.Count) { $Msg = ($argv[$i..($argv.Count - 1)] -join ' ') }
      $i = $argv.Count
      break
    }
    default {
      if ($argv[$i] -like '-*') {
        Write-Host "x unknown flag: $($argv[$i])"
        exit 1
      }
      $Msg = ($argv[$i..($argv.Count - 1)] -join ' ')
      $i = $argv.Count
      break
    }
  }
}

if ([string]::IsNullOrWhiteSpace($Msg)) {
  try {
    if ([Console]::IsInputRedirected) {
      $stdin = [Console]::In.ReadToEnd()
      if (-not [string]::IsNullOrWhiteSpace($stdin)) { $Msg = $stdin.TrimEnd() }
    }
  } catch {
    # ignore stdin read issues
  }
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if (-not (Test-GitRepo)) {
  Write-Host 'x not a git repository'
  exit 1
}

$conflictFiles = @(Get-ConflictMarkerFiles)
if ($conflictFiles.Count -gt 0) {
  $list = $conflictFiles -join ' '
  Write-Host "x merge conflicts in $list - resolve before committing"
  exit 1
}

$allChanged = @(Get-AllChangedFiles)
if ($allChanged.Count -eq 0) {
  Write-Host '(none) nothing to commit'
  exit 0
}

$fileCount = $allChanged.Count

$detached = $false
try {
  git symbolic-ref -q HEAD 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { $detached = $true }
} catch {
  $detached = $true
}

if ($Draft) {
  Write-Host 'Draft commit message:'
  Write-Host "  $Msg"
  Write-Host ''
  Write-Host 'Run /signal-commit to confirm, or edit and pass as: /signal-commit "your message"'
  exit 0
}

if ($Dry) {
  Write-Host "Would stage: $fileCount file(s)"
  Write-Host "Would commit: $Msg"
  if ($Push) {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { $branch = 'HEAD' }
    Write-Host "Would push -> origin/$branch"
  } else {
    Write-Host 'Would not push (use --push to push)'
  }
  exit 0
}

if ($Split -and ($Msg -match "`n")) {
  $messages = @(
    $Msg -split "`r?`n" |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ }
  )

  git add -A 2>$null | Out-Null

  foreach ($commitMsg in $messages) {
    if ([string]::IsNullOrWhiteSpace($commitMsg)) { continue }
    $commitMsg = Normalize-Message $commitMsg
    $scope = Get-ScopeFromMessage $commitMsg

    git restore --staged . 2>$null | Out-Null

    if ($scope) {
      $sc = $scope.ToLowerInvariant()
      $matching = @(git diff --name-only 2>$null | Where-Object { $_.ToLowerInvariant().Contains($sc) })
      $untrackedMatching = @(git ls-files --others --exclude-standard 2>$null | Where-Object { $_.ToLowerInvariant().Contains($sc) })
      $allMatching = @($matching + $untrackedMatching | Sort-Object -Unique)
      if ($allMatching.Count -gt 0) {
        git add -- @allMatching 2>$null | Out-Null
      } else {
        git add -A 2>$null | Out-Null
      }
    } else {
      git add -A 2>$null | Out-Null
    }

    $staged = @(git diff --staged --name-only 2>$null)
    if ($staged.Count -eq 0) { continue }

    $fcount = $staged.Count
    $stats = Get-Stats
    git commit -m $commitMsg --quiet 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host "x git commit failed for: $commitMsg"
      exit 1
    }
    Write-Host "+ $commitMsg [$fcount file(s), $stats]"
  }

  $remainingStaged = @(git diff --name-only 2>$null)
  $remainingUntracked = @(git ls-files --others --exclude-standard 2>$null)
  if ($remainingStaged.Count -gt 0 -or $remainingUntracked.Count -gt 0) {
    git add -A 2>$null | Out-Null
    $leftoverFiles = @(git diff --staged --name-only 2>$null)
    $leftoverCount = $leftoverFiles.Count
    $leftoverStats = Get-Stats
    $lastLine = $messages[-1]
    $fallbackType = 'chore'
    if ($lastLine -match "^([a-z]+)") { $fallbackType = $Matches[1] }
    $fallbackMsg = "${fallbackType}: apply remaining changes"
    $fallbackMsg = Normalize-Message $fallbackMsg
    git commit -m $fallbackMsg --quiet 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host "x git commit failed for leftover changes"
      exit 1
    }
    Write-Host "+ $fallbackMsg [$leftoverCount file(s), $leftoverStats]"
  }

  if ($detached) {
    Write-Host '? detached HEAD - push will require explicit ref'
  }
} else {
  if ([string]::IsNullOrWhiteSpace($Msg)) {
    Write-Host 'x missing commit message'
    exit 1
  }
  $Msg = Normalize-Message $Msg
  git add -A 2>$null | Out-Null
  $stats = Get-Stats
  $fcount = @(git diff --staged --name-only 2>$null).Count
  git commit -m $Msg --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'x git commit failed'
    exit 1
  }
  Write-Host "+ $Msg [$fcount file(s), $stats]"
  if ($detached) {
    Write-Host '? detached HEAD - push will require explicit ref'
  }
}

if ($Push) {
  $branch = git rev-parse --abbrev-ref HEAD 2>$null
  if ($LASTEXITCODE -ne 0) { $branch = 'HEAD' }
  git push 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "+ pushed -> origin/$branch"
  } else {
    git push --set-upstream origin $branch 2>$null | Out-Null
    Write-Host "+ pushed -> origin/$branch"
  }
}
