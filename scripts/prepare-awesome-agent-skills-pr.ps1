#Requires -Version 5.1
# Clone VoltAgent/awesome-agent-skills, apply SIGNAL patch, leave a temp tree for you to push to YOUR fork.
# Prerequisite: fork https://github.com/VoltAgent/awesome-agent-skills to your GitHub account (e.g. mattbaconz/awesome-agent-skills).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$Patch = Join-Path $RepoRoot 'contrib\awesome-agent-skills-add-signal.patch'
if (-not (Test-Path -LiteralPath $Patch)) {
  Write-Error "Missing patch: $Patch"
}

$tmp = Join-Path $env:TEMP ('awesome-agent-skills-pr-' + [Guid]::NewGuid().ToString('n'))
Write-Host "Cloning VoltAgent/awesome-agent-skills -> $tmp" -ForegroundColor Cyan
git clone --depth 1 https://github.com/VoltAgent/awesome-agent-skills.git $tmp
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location $tmp
git checkout -b add-mattbaconz-signal 2>$null
git apply --ignore-whitespace $Patch
if ($LASTEXITCODE -ne 0) {
  Write-Error 'git apply failed — patch may need updating if upstream README changed.'
}

git add README.md
git commit -m "docs: add mattbaconz/signal to community skills"

Write-Host ""
Write-Host "Done. Patched clone at:" -ForegroundColor Green
Write-Host "  $tmp"
Write-Host ""
Write-Host "Next (replace YOUR_USER if needed):" -ForegroundColor Yellow
Write-Host "  1. Fork: https://github.com/VoltAgent/awesome-agent-skills/fork"
Write-Host "  2. git remote add mine https://github.com/YOUR_USER/awesome-agent-skills.git"
Write-Host "  3. git push -u mine add-mattbaconz-signal"
Write-Host "  4. Open PR: compare add-mattbaconz-signal -> VoltAgent/awesome-agent-skills main"
Write-Host ""
