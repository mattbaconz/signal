#Requires -Version 5.1
# Clone VoltAgent/awesome-agent-skills, apply SIGNAL patch, leave a temp tree for you to push to YOUR fork.
# Prerequisite: fork https://github.com/VoltAgent/awesome-agent-skills to your GitHub account (e.g. mattbaconz/awesome-agent-skills).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GitQuiet {
  param([Parameter(Mandatory = $true)][string[]] $Arguments)
  $prevEa = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  # Do not pipe to Out-Null — pipelines can make $LASTEXITCODE unreliable for native commands.
  $null = & git @Arguments 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEa
  return $code
}

function Invoke-GitWithOutput {
  param([Parameter(Mandatory = $true)][string[]] $Arguments)
  $prevEa = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  $out = & git @Arguments 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEa
  return @{ Code = $code; Out = $out }
}

$RepoRoot = Split-Path $PSScriptRoot -Parent
$Patch = Join-Path $RepoRoot 'contrib\awesome-agent-skills-add-signal.patch'
if (-not (Test-Path -LiteralPath $Patch)) {
  Write-Error "Missing patch: $Patch"
}

$tmp = Join-Path $env:TEMP ('awesome-agent-skills-pr-' + [Guid]::NewGuid().ToString('n'))
Write-Host "Cloning VoltAgent/awesome-agent-skills -> $tmp" -ForegroundColor Cyan
$c = Invoke-GitQuiet -Arguments @('clone', '--depth', '1', 'https://github.com/VoltAgent/awesome-agent-skills.git', $tmp)
if ($c -ne 0) { exit $c }

$c = Invoke-GitQuiet -Arguments @('-C', $tmp, 'checkout', '-b', 'add-mattbaconz-signal')
if ($c -ne 0) { exit $c }

# Shallow temp clone has no author; commit would fail with exit 128 without local identity.
$c = Invoke-GitQuiet -Arguments @('-C', $tmp, 'config', 'user.email', 'signal-prepare@local.invalid')
if ($c -ne 0) { exit $c }
$c = Invoke-GitQuiet -Arguments @('-C', $tmp, 'config', 'user.name', 'SIGNAL prepare-awesome script')
if ($c -ne 0) { exit $c }

$r = Invoke-GitWithOutput -Arguments @('-C', $tmp, 'apply', '--ignore-whitespace', $Patch)
if ($r.Code -ne 0) {
  Write-Error 'git apply failed — patch may need updating if upstream README changed.'
}

$c = Invoke-GitQuiet -Arguments @('-C', $tmp, 'add', 'README.md')
if ($c -ne 0) { exit $c }

$r = Invoke-GitWithOutput -Arguments @('-C', $tmp, 'commit', '-m', 'docs: add mattbaconz/signal to community skills')
if ($r.Code -ne 0) {
  Write-Error 'git commit failed (nothing to commit?)'
}

Write-Host ""
Write-Host "Done. Patched clone at:" -ForegroundColor Green
Write-Host "  $tmp"
Write-Host ""
Write-Host "Next (replace YOUR_USER if needed):" -ForegroundColor Yellow
Write-Host "  1. Fork: https://github.com/VoltAgent/awesome-agent-skills/fork"
Write-Host "  2. cd `"$tmp`""
Write-Host "  3. git remote add mine https://github.com/YOUR_USER/awesome-agent-skills.git"
Write-Host "  4. git push -u mine add-mattbaconz-signal"
Write-Host "  5. Open PR: compare add-mattbaconz-signal -> VoltAgent/awesome-agent-skills main"
Write-Host ""
