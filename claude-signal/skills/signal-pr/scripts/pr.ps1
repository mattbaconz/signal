#Requires -Version 5.1
# SIGNAL v0.4.0 - pr.ps1
# Usage: .\pr.ps1 [--draft] [--dry] [--pr-draft] [--] "message"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dry = $false
$draft = $false
$prDraft = $false
$forward = New-Object System.Collections.Generic.List[string]

foreach ($arg in $args) {
  switch -Regex ([string]$arg) {
    '^(--dry|-dry)$' { $dry = $true; $forward.Add('--dry'); continue }
    '^(--draft|-draft)$' { $draft = $true; $forward.Add('--draft'); continue }
    '^(--pr-draft|-pr-draft)$' { $prDraft = $true; continue }
    default { $forward.Add([string]$arg) }
  }
}

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$repoSkills = Split-Path (Split-Path $scriptDir -Parent) -Parent
$pushScript = Join-Path $repoSkills 'signal-push\scripts\push.ps1'
if (-not (Test-Path -LiteralPath $pushScript)) {
  Write-Host "x missing push script: $pushScript"
  exit 1
}

if ($dry -or $draft) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $pushScript @forward
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  if ($dry) { Write-Host 'Would open PR with gh pr create --fill' }
  if ($draft) { Write-Host 'Draft would open PR with gh pr create --fill' }
  exit 0
}

gh --version *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'x gh CLI required'
  exit 1
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $pushScript @forward
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ghArgs = @('pr', 'create', '--fill')
if ($prDraft) { $ghArgs += '--draft' }
& gh @ghArgs
exit $LASTEXITCODE
