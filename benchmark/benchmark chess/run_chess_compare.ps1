#Requires -Version 5.1
# Run shared prompt.txt in baseline vs SIGNAL GEMINI.md folders; compare Gemini CLI JSON stats.
# Uses node + gemini.js -p (not stdin) so JSON is not mixed with node stderr noise.
param(
  [string]$Model = $null
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
Set-Location -LiteralPath $here

$geminiCmd = (Get-Command gemini -ErrorAction Stop).Source
# Directory that contains gemini.cmd / gemini.ps1 (not the parent of bin).
$geminiBin = Split-Path $geminiCmd
$geminiJs = Join-Path $geminiBin "node_modules\@google\gemini-cli\bundle\gemini.js"
if (-not (Test-Path -LiteralPath $geminiJs)) {
  Write-Error "Could not find gemini.js at $geminiJs (install @google/gemini-cli)."
}
$node = (Get-Command node -ErrorAction Stop).Source

$promptPath = Join-Path $here "prompt.txt"
if (-not (Test-Path -LiteralPath $promptPath)) {
  Write-Error "Missing $promptPath"
}
$promptText = Get-Content -LiteralPath $promptPath -Raw
if ([string]::IsNullOrWhiteSpace($promptText)) {
  Write-Error "prompt.txt is empty"
}

$baselineDir = Join-Path $here "chess baseline (no signal)"
$signalDir = Join-Path $here "chess signal (signal skill used)"
foreach ($d in @($baselineDir, $signalDir)) {
  if (-not (Test-Path -LiteralPath $d)) {
    Write-Error "Missing folder: $d"
  }
}

function Get-TokenPrimaryMax {
  param($stats)
  if (-not $stats -or -not $stats.models) { return 0 }
  $max = 0
  foreach ($p in $stats.models.PSObject.Properties) {
    $m = $p.Value
    if ($m.tokens -and $null -ne $m.tokens.total) {
      $t = [int]$m.tokens.total
      if ($t -gt $max) { $max = $t }
    }
  }
  return $max
}

function Get-PromptTokens {
  param($stats)
  if (-not $stats -or -not $stats.models) { return $null }
  foreach ($p in $stats.models.PSObject.Properties) {
    $m = $p.Value
    if ($m.tokens -and $null -ne $m.tokens.prompt) {
      return [int]$m.tokens.prompt
    }
  }
  return $null
}

function Invoke-GeminiJson {
  param([string]$WorkingDir)
  Push-Location -LiteralPath $WorkingDir
  try {
    if ($Model) {
      $raw = & $node $geminiJs -m $Model -p $promptText -o json --approval-mode plan 2>$null
    } else {
      $raw = & $node $geminiJs -p $promptText -o json --approval-mode plan 2>$null
    }
    if (-not $raw) {
      throw "empty stdout from gemini"
    }
    return ($raw | ConvertFrom-Json)
  } finally {
    Pop-Location
  }
}

$runs = @()

foreach ($label in @("baseline", "signal")) {
  $dir = if ($label -eq "baseline") { $baselineDir } else { $signalDir }
  Write-Host "=== $label ===" -ForegroundColor Yellow
  try {
    $obj = Invoke-GeminiJson -WorkingDir $dir
    if ($obj.error) {
      throw $obj.error.message
    }
    $tokP = Get-TokenPrimaryMax $obj.stats
    $promptTok = Get-PromptTokens $obj.stats
    $resp = if ($obj.response) { [string]$obj.response } else { "" }
    $modelName = $null
    if ($obj.stats -and $obj.stats.models) {
      $modelName = @($obj.stats.models.PSObject.Properties.Name)[0]
    }
    $runs += [PSCustomObject]@{
      label = $label
      ok = $true
      model = $modelName
      tokens_primary_max = $tokP
      prompt_tokens = $promptTok
      response_chars = $resp.Length
      session_id = [string]$obj.session_id
    }
    Write-Host "  model=$modelName tokens_total_max=$tokP prompt_tokens=$promptTok response_chars=$($resp.Length)"
  } catch {
    $runs += [PSCustomObject]@{
      label = $label
      ok = $false
      error = $_.Exception.Message
    }
    Write-Host "  x $($_.Exception.Message)" -ForegroundColor Red
  }
}

$baseline = $runs | Where-Object { $_.label -eq "baseline" } | Select-Object -First 1
$signal = $runs | Where-Object { $_.label -eq "signal" } | Select-Object -First 1

$deltaPrimary = $null
$deltaPct = $null
$deltaCharsPct = $null
if ($baseline.ok -and $signal.ok -and $baseline.tokens_primary_max -gt 0) {
  $deltaPrimary = [int]$signal.tokens_primary_max - [int]$baseline.tokens_primary_max
  $deltaPct = [math]::Round(($deltaPrimary / [double]$baseline.tokens_primary_max) * 100, 1)
}
if ($baseline.ok -and $signal.ok -and $baseline.response_chars -gt 0) {
  $deltaCharsPct = [math]::Round((1 - ([double]$signal.response_chars / [double]$baseline.response_chars)) * 100, 1)
}

$out = [PSCustomObject]@{
  prompt_file = "prompt.txt"
  gemini_js = $geminiJs
  model_flag = $Model
  generated_at = (Get-Date).ToString("o")
  runs = @($runs)
  compare = [PSCustomObject]@{
    baseline_tokens_primary_max = if ($baseline.ok) { $baseline.tokens_primary_max } else { $null }
    signal_tokens_primary_max = if ($signal.ok) { $signal.tokens_primary_max } else { $null }
    delta_tokens_primary_max = $deltaPrimary
    delta_pct_total_vs_baseline = $deltaPct
    baseline_response_chars = if ($baseline.ok) { $baseline.response_chars } else { $null }
    signal_response_chars = if ($signal.ok) { $signal.response_chars } else { $null }
    pct_fewer_response_chars_vs_baseline = $deltaCharsPct
    note = "tokens_primary_max is max(stats.models.*.tokens.total). Single-turn: shorter replies can coexist with higher total tokens if prompt/input context grows (e.g. GEMINI.md + skills). See benchmark chess README."
  }
}

$outPath = Join-Path $here "results_chess_compare.json"
$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding utf8
Write-Host "`nWrote $outPath" -ForegroundColor Green

if (-not ($baseline.ok -and $signal.ok)) {
  exit 1
}
if ($null -ne $deltaCharsPct) {
  Write-Host "Response chars: ~$deltaCharsPct% fewer in SIGNAL folder vs baseline (same prompt)." -ForegroundColor Cyan
}
exit 0
