#Requires -Version 5.1
# One-command SIGNAL benchmark wrapper.
# Default: deterministic no-network proof run + dry-run live plans.
# Live: add -Live to run Gemini output scenarios and write local ignored JSON.
[CmdletBinding()]
param(
  [switch]$Live,
  [switch]$LongSession,
  [switch]$DryRun,
  [string]$Model,
  [int]$MaxLiveScenarios = 1,
  [int]$PerCallTimeoutSeconds = 90,
  [string]$OutDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Run = Join-Path $RepoRoot 'benchmark\run.ps1'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $Run)) {
  throw "Missing benchmark runner: $Run"
}

function New-RunId {
  return (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
}

function Invoke-Step {
  param(
    [string]$Name,
    [string[]]$StepArgs
  )
  Write-Host ""
  Write-Host "== $Name" -ForegroundColor Cyan
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Run @StepArgs
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

$runId = New-RunId
$targetDir = if ($OutDir) { $OutDir } else { Join-Path $RepoRoot 'benchmark\results\local' }
if (-not $DryRun -and -not (Test-Path -LiteralPath $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$summary = [ordered]@{
  schema_version = '0.4.0'
  run_id = $runId
  mode = if ($Live) { 'live' } else { 'static' }
  long_session = [bool]$LongSession
  model = $Model
  generated_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  artifacts = @()
}

Invoke-Step 'static proof suite' @('-Mode', 'Static')
Invoke-Step 'output benchmark plan' @('-Mode', 'Output', '-DryRun')
Invoke-Step 'input-compress fidelity gate' @('-Mode', 'InputCompress', '-DryRun')
Invoke-Step 'caveman-style comparison plan' @('-Mode', 'CompareCaveman', '-DryRun')

if ($Live) {
  $livePath = Join-Path $targetDir "auto-output-$runId.json"
  $liveArgs = @(
    '-Mode', 'Output',
    '-Live',
    '-WriteResults',
    '-OutFile', $livePath,
    '-MaxScenarios', "$MaxLiveScenarios",
    '-PerCallTimeoutSeconds', "$PerCallTimeoutSeconds"
  )
  if ($Model) { $liveArgs += @('-Model', $Model) }
  if ($DryRun) {
    Write-Host ""
    Write-Host "DRY: would run live output benchmark -> $livePath" -ForegroundColor Yellow
  } else {
    Invoke-Step 'live output benchmark' $liveArgs
    $summary.artifacts += $livePath
  }
}

if ($LongSession) {
  $lsArgs = @('-Mode', 'LongSession', '-Quick')
  if ($DryRun) {
    Write-Host ""
    Write-Host 'DRY: would run long-session quick benchmark' -ForegroundColor Yellow
  } else {
    Invoke-Step 'long-session quick benchmark' $lsArgs
    $summary.artifacts += 'benchmark/long-session/results_*.json'
  }
}

if (-not $DryRun) {
  $summaryPath = Join-Path $targetDir "auto-summary-$runId.json"
  $json = $summary | ConvertTo-Json -Depth 6
  [System.IO.File]::WriteAllText($summaryPath, $json, $Utf8NoBom)
  Write-Host ""
  Write-Host "Wrote $summaryPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "auto-benchmark: OK ($($summary.mode))" -ForegroundColor Green
