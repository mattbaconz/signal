#Requires -Version 5.1
# SIGNAL v0.4.0 - commit.ps1
# Usage: .\commit.ps1 [--draft] [--dry] [--push] [--split] [--] "message"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dry = $false
$draft = $false
$push = $false
$split = $false
$messages = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $args.Count; $i++) {
  $arg = [string]$args[$i]
  switch -Regex ($arg) {
    '^(--dry|-dry)$' { $dry = $true; continue }
    '^(--draft|-draft)$' { $draft = $true; continue }
    '^(--push|-push)$' { $push = $true; continue }
    '^(--split|-split)$' { $split = $true; continue }
    '^--$' {
      if ($i + 1 -lt $args.Count) {
        foreach ($tail in $args[($i + 1)..($args.Count - 1)]) { $messages.Add([string]$tail) }
      }
      $i = $args.Count
      break
    }
    default { $messages.Add($arg) }
  }
}

$messageText = ($messages -join ' ').Trim()
if (-not $messageText) {
  Write-Error 'Missing commit message'
  exit 1
}

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x not a git repository'
  exit 1
}

function Get-ChangedFiles {
  $files = New-Object System.Collections.Generic.List[string]
  $lines = git status --porcelain
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
    $path = $line.Substring(3).Trim()
    if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1].Trim() }
    $files.Add($path)
  }
  return $files
}

function Get-Scope([string]$msg) {
  if ($msg -match '^[a-z]+(?:\(([^)]+)\))?:') { return $Matches[1] }
  return ''
}

function Matches-Scope([string]$path, [string]$scope) {
  if ([string]::IsNullOrWhiteSpace($scope)) { return $true }
  $p = $path.Replace('\', '/').ToLowerInvariant()
  $s = $scope.ToLowerInvariant()
  return $p -eq $s -or $p.StartsWith("$s/") -or $p.Contains("/$s/") -or $p.Contains($s)
}

function Push-CurrentBranch {
  $branch = (git branch --show-current).Trim()
  if (-not $branch) {
    Write-Host 'x cannot push in detached HEAD'
    exit 1
  }
  $upstream = (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null)
  if ($LASTEXITCODE -eq 0 -and $upstream) {
    git push
  } else {
    git push --set-upstream origin $branch
  }
}

$changed = @(Get-ChangedFiles)
if ($changed.Count -eq 0) {
  Write-Host '∅ nothing to commit'
  exit 0
}

if ($dry -or $draft) {
  $mode = if ($dry) { 'Would' } else { 'Draft would' }
  Write-Host "$mode stage: $($changed.Count) files"
  Write-Host "$mode commit: $messageText"
  if ($push) { Write-Host "$mode push current branch" }
  exit 0
}

if ($split) {
  $commitMessages = @($messageText -split "(`r`n|`n|`r)" | Where-Object { $_.Trim() })
  if ($commitMessages.Count -eq 0) {
    Write-Error 'Missing split commit messages'
    exit 1
  }

  git reset -q
  $remaining = @(Get-ChangedFiles)
  foreach ($msg in $commitMessages) {
    $scope = Get-Scope $msg
    $matches = @($remaining | Where-Object { Matches-Scope $_ $scope })
    if ($matches.Count -eq 0 -and $msg -eq $commitMessages[-1]) { $matches = $remaining }
    if ($matches.Count -eq 0) { continue }
    git add -- $matches
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { continue }
    git commit -m $msg
    $remaining = @(Get-ChangedFiles)
  }
} else {
  git add -A
  git diff --cached --quiet
  if ($LASTEXITCODE -eq 0) {
    Write-Host '∅ nothing to commit'
    exit 0
  }
  git commit -m $messageText
}

if ($push) { Push-CurrentBranch }
