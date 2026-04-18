#Requires -Version 5.1
# SIGNAL - reproducible token estimates (4 chars/token heuristic, same as README).
# Run from repo root:  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmark.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-EstimatedTokens([string]$Text) {
  if ([string]::IsNullOrEmpty($Text)) { return 0 }
  return [int][math]::Ceiling($Text.Length / 4.0)
}

function Show-Row([string]$Label, [int]$VerboseTok, [int]$SignalTok) {
  $saved = $VerboseTok - $SignalTok
  $pct = if ($VerboseTok -gt 0) { [math]::Round(100.0 * $saved / $VerboseTok, 1) } else { 0 }
  $ratio = if ($SignalTok -gt 0) { [math]::Round($VerboseTok / $SignalTok, 1) } else { [double]::PositiveInfinity }
  Write-Host ('  {0,-32} verbose ~{1,5} tok | SIGNAL ~{2,4} tok | save ~{3,5} tok ({4,5}% smaller, {5}x vs SIGNAL)' -f $Label, $VerboseTok, $SignalTok, $saved, $pct, $ratio)
}

Write-Host ''
Write-Host 'SIGNAL benchmark - estimated tokens (ceil(charLength/4); not billed API tokens)' -ForegroundColor Cyan
Write-Host ''

# --- Fixture A: 10-turn transcript vs checkpoint (see references/checkpoint.md) ---
$transcriptA = @'
Turn 1: User asked to add JWT auth to Express API. We discussed strategy.
Turn 2: Decided to use jsonwebtoken library, store refresh tokens in Redis.
Turn 3: Implemented /auth/login endpoint. Tests failing.
Turn 4: Fixed tests - issue was bcrypt async not being awaited.
Turn 5: Started /auth/refresh endpoint. Hit a Redis connection issue.
Turn 6: Resolved Redis issue - was wrong env var name.
Turn 7: /auth/refresh endpoint complete. Moving to /auth/logout.
Turn 8: /auth/logout done. Now need to add middleware to protected routes.
Turn 9: Middleware added. Found issue - token expiry not being checked.
Turn 10: [current turn - expiry fix in progress]
'@.Trim()

$checkpointA = @'
CKPT[2]:
  §project=express-api §stack=node+jwt+redis
  progress=[login✓, refresh✓, logout✓, middleware/, expiry-check∅]
  next=fix token expiry check in middleware
'@.Trim()

# --- Fixture B: verbose bug line vs SIGNAL pointer (README before/after) ---
$verboseB = 'The issue is in auth.js around line 47. There is a null reference error occurring when the array is empty. You should add a guard clause to handle this case. I am fairly confident this is the root cause.'
$signalB = 'auth.js:47|null ref|guard'

# --- Fixture C: hedging vs confidence token ---
$verboseC = 'I am fairly confident that...'
$signalC = '[0.95]'

Write-Host 'Scenarios:' -ForegroundColor Yellow
Show-Row 'A: 10-turn history vs CKPT' (Get-EstimatedTokens $transcriptA) (Get-EstimatedTokens $checkpointA)
Show-Row 'B: bug paragraph vs SIGNAL line' (Get-EstimatedTokens $verboseB) (Get-EstimatedTokens $signalB)
Show-Row 'C: hedging vs [conf]' (Get-EstimatedTokens $verboseC) (Get-EstimatedTokens $signalC)

$vA = Get-EstimatedTokens $transcriptA
$sA = Get-EstimatedTokens $checkpointA
$pctA = [math]::Round(100.0 * ($vA - $sA) / $vA, 1)
$ratioA = [math]::Round($vA / $sA, 1)
Write-Host ''
Write-Host ("Checkpoint A: verbatim ~{0} tok; CKPT ~{1} tok -> ~{2}% fewer than full transcript (~{3}x compression)." -f $vA, $sA, $pctA, $ratioA) -ForegroundColor Green
$tokA = Get-EstimatedTokens $transcriptA
Write-Host ''
Write-Host ("Note: Scenario A uses the compact 10-line summary (see references/checkpoint.md; ~{0} tok here). A fuller thread would show a larger ratio vs the same CKPT." -f $tokA) -ForegroundColor DarkGray
Write-Host 'Real sessions vary by model, tool output, and host overhead.' -ForegroundColor DarkGray
Write-Host ''
exit 0
