# Long-session benchmark for Gemini CLI.
# Dot-sources shared helpers from benchmark/lib/gemini-invoke.ps1
#
# Baseline: ONE session via --resume; each turn only sends the new user line.
# SIGNAL-3: CHUNKED sessions (every 5 turns); first message of chunk = CKPT + user; resume inside chunk.
#
# Usage:
#   .\run_long_session.ps1 -Quick
#   .\run_long_session.ps1 -Smoke          # 6 turns — at least one CKPT chunk boundary for SIGNAL
#   .\run_long_session.ps1 -FixtureDir .   # cwd for gemini (optional; default: this folder)
#   .\run_long_session.ps1 -SeedGeminiMinTemplate  # copy repo templates/gemini-GEMINI.min.md -> GEMINI.md in FixtureDir (requires -FixtureDir)
#   .\run_long_session.ps1 -DelayMs 500    # pause between turns (429 / quota spacing)

param(
  [switch]$Quick,
  [switch]$Smoke,
  [string]$FixtureDir = $null,
  [switch]$SeedGeminiMinTemplate,
  [int]$DelayMs = 0
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lib = Join-Path (Split-Path $here -Parent) "lib\gemini-invoke.ps1"
. $lib

if ($SeedGeminiMinTemplate -and -not $FixtureDir) {
  throw "SeedGeminiMinTemplate requires -FixtureDir (directory to receive GEMINI.md)."
}

$workDir = if ($FixtureDir) {
  (Resolve-Path -LiteralPath $FixtureDir).Path
} else {
  $here
}

if ($SeedGeminiMinTemplate) {
  $repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
  $src = Join-Path $repoRoot "templates\gemini-GEMINI.min.md"
  if (-not (Test-Path -LiteralPath $src)) { throw "Missing $src" }
  Copy-Item -LiteralPath $src -Destination (Join-Path $workDir "GEMINI.md") -Force
  Write-Host "Seeded GEMINI.md from templates/gemini-GEMINI.min.md into $workDir" -ForegroundColor DarkCyan
}

$repoRootMeta = (Resolve-Path (Join-Path $here "..\..")).Path
$runMeta = New-BenchmarkRunMetadata -RepoRoot $repoRootMeta

function Get-CkptLine {
  param([int]$Index, [int]$NextTurn1Based)
  return "CKPT[$Index] project=move-validator next=turn$NextTurn1Based progress=block${Index}OK"
}

function Step-Delay {
  if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
}

$all = Get-Content (Join-Path $here "turns.json") -Raw | ConvertFrom-Json
if ($all -isnot [System.Array]) { $all = @($all) }

if ($Smoke) {
  $take = [Math]::Min(6, $all.Length)
} elseif ($Quick) {
  $take = [Math]::Min(5, $all.Length)
} else {
  $take = $all.Length
}
$turns = $all | Select-Object -First $take
$checkpointEvery = 5
$n = $turns.Count

Write-Host "WorkingDirectory=$workDir  turns=$n  (Quick=$Quick Smoke=$Smoke)  DelayMs=$DelayMs" -ForegroundColor Cyan
Write-Host "Run metadata: gemini=$($runMeta.gemini_cli_version) auth_hint=$($runMeta.auth_mode_hint) run_id=$($runMeta.run_id)" -ForegroundColor DarkGray

# --- Baseline: one session, resume after turn 1 ---
Write-Host "=== Baseline (single session, --resume) ===" -ForegroundColor Yellow
$sumBaselinePrimary = 0
$sumBaselineSum = 0
$cumCharsBaseline = 0
$rowsBaseline = @()
$sessionBaseline = $null
$i = 0
foreach ($userMsg in $turns) {
  $i++
  if ($i -eq 1) {
    $jsonText = Invoke-GeminiStdinJson -PromptText $userMsg -ResumeSessionId $null -WorkingDirectory $workDir
  } else {
    $jsonText = Invoke-GeminiStdinJson -PromptText $userMsg -ResumeSessionId $sessionBaseline -WorkingDirectory $workDir
  }
  $obj = Parse-GeminiJson $jsonText
  $sessionBaseline = [string]$obj.session_id
  if ([string]::IsNullOrWhiteSpace($sessionBaseline)) { throw "empty session_id from Gemini (cannot resume baseline)." }
  $tokP = Get-TokenPrimaryMax $obj.stats
  $tokS = Get-TokenSumAllModels $obj.stats
  $f = Get-FirstModelTokenFields $obj.stats
  $sumBaselinePrimary += $tokP
  $sumBaselineSum += $tokS
  $cumCharsBaseline += $userMsg.Length
  $rowsBaseline += [PSCustomObject]@{
    turn = $i
    tokens_primary_max = $tokP
    tokens_sum_all_models = $tokS
    tokens_prompt_first_model = $f.prompt
    tokens_output_est_first_model = $f.output
    model_first = $f.model
    user_message_chars = $userMsg.Length
  }
  Write-Host "  turn $i primary_max=$tokP sum_all=$tokS (user chars $($userMsg.Length))"
  Step-Delay
}

# --- SIGNAL-3: chunked sessions ---
Write-Host ""
Write-Host "=== SIGNAL-3 (chunked sessions, CKPT every $checkpointEvery turns) ===" -ForegroundColor Yellow
$sumSignalPrimary = 0
$sumSignalSum = 0
$cumCharsSignal = 0
$rowsSignal = @()
$sessionSignal = $null
$i = 0
$chunkIndex = 0
foreach ($userMsg in $turns) {
  $i++
  $isChunkStart = ($i -eq 1) -or (($i - 1) % $checkpointEvery -eq 0)
  if ($isChunkStart) {
    $chunkIndex = [int][math]::Ceiling($i / $checkpointEvery)
    if ($i -eq 1) {
      $firstPayload = $userMsg
      $cumCharsSignal += $userMsg.Length
    } else {
      $ckpt = Get-CkptLine -Index ($chunkIndex - 1) -NextTurn1Based $i
      $firstPayload = $ckpt + "`n`n" + $userMsg
      $cumCharsSignal += $firstPayload.Length
    }
    $jsonText = Invoke-GeminiStdinJson -PromptText $firstPayload -ResumeSessionId $null -WorkingDirectory $workDir
    $obj = Parse-GeminiJson $jsonText
    $sessionSignal = [string]$obj.session_id
    if ([string]::IsNullOrWhiteSpace($sessionSignal)) { throw "empty session_id from Gemini (cannot resume SIGNAL chunk)." }
    $tokP = Get-TokenPrimaryMax $obj.stats
    $tokS = Get-TokenSumAllModels $obj.stats
    $f = Get-FirstModelTokenFields $obj.stats
    $sumSignalPrimary += $tokP
    $sumSignalSum += $tokS
    $rowsSignal += [PSCustomObject]@{
      turn = $i
      tokens_primary_max = $tokP
      tokens_sum_all_models = $tokS
      tokens_prompt_first_model = $f.prompt
      tokens_output_est_first_model = $f.output
      model_first = $f.model
      first_message_chars = $firstPayload.Length
      chunk_start = $true
    }
    Write-Host "  turn $i chunk=$chunkIndex START primary_max=$tokP sum_all=$tokS (first msg chars $($firstPayload.Length))"
    Step-Delay
    continue
  }
  $jsonText = Invoke-GeminiStdinJson -PromptText $userMsg -ResumeSessionId $sessionSignal -WorkingDirectory $workDir
  $obj = Parse-GeminiJson $jsonText
  $sessionSignal = [string]$obj.session_id
  if ([string]::IsNullOrWhiteSpace($sessionSignal)) { throw "empty session_id from Gemini (SIGNAL resume)." }
  $tokP = Get-TokenPrimaryMax $obj.stats
  $tokS = Get-TokenSumAllModels $obj.stats
  $f = Get-FirstModelTokenFields $obj.stats
  $sumSignalPrimary += $tokP
  $sumSignalSum += $tokS
  $cumCharsSignal += $userMsg.Length
  $rowsSignal += [PSCustomObject]@{
    turn = $i
    tokens_primary_max = $tokP
    tokens_sum_all_models = $tokS
    tokens_prompt_first_model = $f.prompt
    tokens_output_est_first_model = $f.output
    model_first = $f.model
    user_message_chars = $userMsg.Length
    chunk_start = $false
  }
  Write-Host "  turn $i primary_max=$tokP sum_all=$tokS (user chars $($userMsg.Length))"
  Step-Delay
}

$deltaPrimary = if ($sumBaselinePrimary -gt 0) {
  [math]::Round((($sumSignalPrimary - $sumBaselinePrimary) / $sumBaselinePrimary) * 100, 1)
} else { 0 }

$t1b = [int]$rowsBaseline[0].tokens_primary_max
$t1s = [int]($rowsSignal | Where-Object { $_.turn -eq 1 } | Select-Object -ExpandProperty tokens_primary_max)
$sumBaselineTail = $sumBaselinePrimary - $t1b
$sumSignalTail = $sumSignalPrimary - $t1s
$deltaPrimaryExclT1 = if ($sumBaselineTail -gt 0) {
  [math]::Round((($sumSignalTail - $sumBaselineTail) / $sumBaselineTail) * 100, 1)
} else { 0 }

$deltaChars = if ($cumCharsBaseline -gt 0) {
  [math]::Round((($cumCharsSignal - $cumCharsBaseline) / $cumCharsBaseline) * 100, 1)
} else { 0 }

$outBase = [PSCustomObject]@{
  mode = "baseline_single_session_resume"
  turns = $n
  working_directory = $workDir
  total_tokens_primary_max = $sumBaselinePrimary
  total_tokens_sum_all_models = $sumBaselineSum
  cumulative_user_chars_approx = $cumCharsBaseline
  per_turn = $rowsBaseline
  note = "Each turn sends only the new user line after turn 1 (--resume). Totals are per-turn API stats summed. Protocol benchmark (synthetic CKPT), not live /signal3 skill."
  run_metadata = $runMeta
  generated_at = (Get-Date).ToString("o")
}
$outBase | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $here "results_baseline.json") -Encoding utf8

$outSig = [PSCustomObject]@{
  mode = "signal3_chunked_sessions"
  turns = $n
  checkpoint_every = $checkpointEvery
  working_directory = $workDir
  total_tokens_primary_max = $sumSignalPrimary
  total_tokens_sum_all_models = $sumSignalSum
  cumulative_message_chars_approx = $cumCharsSignal
  per_turn = $rowsSignal
  note = "New session every 5 turns with short CKPT in first message; resume inside chunk. Compare cumulative_message_chars to baseline user_chars."
  run_metadata = $runMeta
  generated_at = (Get-Date).ToString("o")
}
$outSig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $here "results_signal.json") -Encoding utf8

$compare = [PSCustomObject]@{
  turns = $n
  working_directory = $workDir
  baseline_total_primary_max = $sumBaselinePrimary
  signal_total_primary_max = $sumSignalPrimary
  delta_pct_primary_max = $deltaPrimary
  turn1_primary_max_baseline = $t1b
  turn1_primary_max_signal = $t1s
  baseline_primary_max_turns_2_to_n = $sumBaselineTail
  signal_primary_max_turns_2_to_n = $sumSignalTail
  delta_pct_primary_max_excluding_turn1 = $deltaPrimaryExclT1
  baseline_user_chars_sum = $cumCharsBaseline
  signal_message_chars_sum = $cumCharsSignal
  delta_pct_chars = $deltaChars
  interpretation = "Turn 1 often differs wildly (cold start). Prefer delta_pct_primary_max_excluding_turn1 for A/B. With n>5, SIGNAL opens new chunks with a short CKPT. Cached token fields differ OAuth vs API key (see docs/token-metrics.md)."
  run_metadata = $runMeta
  generated_at = (Get-Date).ToString("o")
}
$compare | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $here "results_compare.json") -Encoding utf8

if (-not $Quick) {
  $runDate = Get-Date -Format 'yyyy-MM-dd HH:mm'
  $resultSection = @(
    "",
    "---",
    "",
    "## Full run ($n turns) - $runDate",
    "",
    "| Metric | Baseline | SIGNAL-3 | Delta |",
    "|--------|----------|----------|-------|",
    "| Sum primary_max (all turns) | $sumBaselinePrimary | $sumSignalPrimary | $($deltaPrimary)% |",
    "| Sum primary_max (turns 2-$n, excl. T1 cold start) | $sumBaselineTail | $sumSignalTail | $($deltaPrimaryExclT1)% |",
    "| Cumulative user/message chars | $cumCharsBaseline | $cumCharsSignal | $($deltaChars)% |",
    "",
    "T1 primary_max: baseline=$t1b signal=$t1s (cold-start variance - exclude for clean comparison).",
    "primary_max = max(stats.models.*.tokens.total) per turn (avoids double-counting router + main).",
    "",
    "Artifacts: results_baseline.json, results_signal.json, results_compare.json"
  )

  $resultsPath = Join-Path $here "RESULTS.md"
  $existing = if (Test-Path $resultsPath) { Get-Content $resultsPath -Raw } else { "" }
  $appended = $existing.TrimEnd() + "`n" + ($resultSection -join "`n") + "`n"
  [System.IO.File]::WriteAllText($resultsPath, $appended, [System.Text.Encoding]::UTF8)
}

Write-Host ""
Write-Host "Baseline primary_max total: $sumBaselinePrimary (T1=$t1b)" -ForegroundColor Green
Write-Host "SIGNAL primary_max total:   $sumSignalPrimary (T1=$t1s, all-turn delta $deltaPrimary%)" -ForegroundColor Green
Write-Host "Excl. turn1 primary_max:    $sumBaselineTail vs $sumSignalTail ($deltaPrimaryExclT1%)" -ForegroundColor Yellow
Write-Host "User/message chars:         $cumCharsBaseline vs $cumCharsSignal ($deltaChars%)" -ForegroundColor Cyan
if ($Quick) {
  Write-Host "Wrote JSON in $here (Quick: short run; use -Smoke for 6 turns / CKPT boundary)" -ForegroundColor DarkGray
} else {
  Write-Host "Wrote JSON + RESULTS.md in $here"
}
