# Shared helpers for SIGNAL Gemini CLI benchmarks (dot-source from benchmark/*/ *.ps1).
#Requires -Version 5.1
Set-StrictMode -Version Latest

function Get-GeminiCliExe {
  $geminiCmd = (Get-Command gemini -ErrorAction Stop).Source
  if ($geminiCmd -match '\.ps1$') {
    $geminiCmd = Join-Path (Split-Path $geminiCmd) "gemini.cmd"
  }
  return $geminiCmd
}

function Get-GeminiNodeBundle {
  $geminiCmd = Get-GeminiCliExe
  $geminiBin = Split-Path $geminiCmd
  $geminiJs = Join-Path $geminiBin "node_modules\@google\gemini-cli\bundle\gemini.js"
  if (-not (Test-Path -LiteralPath $geminiJs)) {
    throw "Could not find gemini.js at $geminiJs (install @google/gemini-cli)."
  }
  $node = (Get-Command node -ErrorAction Stop).Source
  return @{
    GeminiExe = $geminiCmd
    GeminiJs  = $geminiJs
    NodeExe   = $node
  }
}

function Get-GeminiVersionLine {
  try {
    $geminiCmd = Get-GeminiCliExe
    $out = & $geminiCmd --version 2>&1
    return ($out | Out-String).Trim()
  } catch {
    return "unknown"
  }
}

function Get-AuthModeHint {
  if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY.Length -gt 0) { return "api_key_env" }
  if ($env:GOOGLE_API_KEY -and $env:GOOGLE_API_KEY.Length -gt 0) { return "google_api_key_env" }
  if ($env:GOOGLE_CLOUD_PROJECT -and $env:GOOGLE_CLOUD_PROJECT.Length -gt 0) { return "gcloud_project_env" }
  return "oauth_or_other"
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

function Get-TokenSumAllModels {
  param($stats)
  if (-not $stats) { return 0 }
  $sum = 0
  if ($stats.models) {
    foreach ($p in $stats.models.PSObject.Properties) {
      $m = $p.Value
      if ($m.tokens -and $null -ne $m.tokens.total) {
        $sum += [int]$m.tokens.total
      }
    }
  }
  return $sum
}

function Get-FirstModelTokenFields {
  param($stats)
  $prompt = $null
  $total = $null
  $output = $null
  if (-not $stats -or -not $stats.models) {
    return @{ prompt = $null; total = $null; output = $null; model = $null }
  }
  foreach ($p in $stats.models.PSObject.Properties) {
    $m = $p.Value
    if (-not $m.tokens) { continue }
    $modelName = $p.Name
    if ($null -ne $m.tokens.total) { $total = [int]$m.tokens.total }
    if ($null -ne $m.tokens.prompt) { $prompt = [int]$m.tokens.prompt }
    if ($null -ne $m.tokens.candidates) { $output = [int]$m.tokens.candidates }
    elseif ($null -ne $m.tokens.output) { $output = [int]$m.tokens.output }
    elseif ($null -ne $prompt -and $null -ne $total) {
      $output = [math]::Max(0, $total - $prompt)
    }
    return @{ prompt = $prompt; total = $total; output = $output; model = $modelName }
  }
  return @{ prompt = $null; total = $null; output = $null; model = $null }
}

function Get-PromptTokens {
  param($stats)
  $f = Get-FirstModelTokenFields $stats
  return $f.prompt
}

function Parse-GeminiJson {
  param([string]$JsonText)
  $obj = $JsonText | ConvertFrom-Json
  # Strict mode: do not touch $obj.error unless the property exists
  $errProp = $obj.PSObject.Properties['error']
  if ($null -ne $errProp -and $null -ne $errProp.Value) {
    $msg = if ($errProp.Value.PSObject.Properties['message']) { $errProp.Value.message } else { [string]$errProp.Value }
    throw $msg
  }
  return $obj
}

function Test-RetryableGeminiFailure {
  param([string]$Message, [int]$ExitCode)
  if ($ExitCode -eq 0) { return $false }
  $m = if ($Message) { $Message.ToLowerInvariant() } else { "" }
  if ($m -match '429|resource exhausted|rate|quota|timeout|temporar') { return $true }
  return $false
}

function Invoke-GeminiStdinJson {
  param(
    [string]$PromptText,
    [string]$ResumeSessionId,
    [string]$WorkingDirectory,
    [int]$MaxRetries = 4,
    [int]$InitialBackoffMs = 1500
  )
  $geminiCmd = Get-GeminiCliExe
  $attempt = 0
  $backoff = $InitialBackoffMs
  while ($true) {
    $attempt++
    try {
      $psi = New-Object System.Diagnostics.ProcessStartInfo
      $psi.FileName = $geminiCmd
      if ($ResumeSessionId) {
        $psi.Arguments = "--resume $ResumeSessionId -o json"
      } else {
        $psi.Arguments = "-o json"
      }
      $psi.WorkingDirectory = $WorkingDirectory
      $psi.UseShellExecute = $false
      $psi.RedirectStandardInput = $true
      $psi.RedirectStandardOutput = $true
      $psi.RedirectStandardError = $true
      $p = [System.Diagnostics.Process]::Start($psi)
      $p.StandardInput.Write($PromptText)
      $p.StandardInput.Close()
      $readOutTask = $p.StandardOutput.ReadToEndAsync()
      $readErrTask = $p.StandardError.ReadToEndAsync()
      $p.WaitForExit()
      $stdout = $readOutTask.Result
      $stderrText = $readErrTask.Result
      if ($p.ExitCode -ne 0) {
        $msg = "gemini exited $($p.ExitCode): $(if ($stdout) { $stdout.Substring(0, [Math]::Min(400, $stdout.Length)) } else { '(empty stdout)' }) | stderr: $(if ($stderrText) { $stderrText.Substring(0, [Math]::Min(600, $stderrText.Length)) } else { '(empty stderr)' })"
        if ($attempt -lt $MaxRetries -and (Test-RetryableGeminiFailure -Message "$msg $stderrText" -ExitCode $p.ExitCode)) {
          Start-Sleep -Milliseconds $backoff
          $backoff = [math]::Min($backoff * 2, 60000)
          continue
        }
        throw $msg
      }
      return $stdout
    } catch {
      if ($attempt -lt $MaxRetries -and (Test-RetryableGeminiFailure -Message $_.Exception.Message -ExitCode 1)) {
        Start-Sleep -Milliseconds $backoff
        $backoff = [math]::Min($backoff * 2, 60000)
        continue
      }
      throw
    }
  }
}

function Invoke-GeminiNodePromptJson {
  param(
    [string]$WorkingDir,
    [string]$PromptText,
    [string]$Model,
    [string]$GeminiJs,
    [string]$NodeExe,
    [int]$MaxRetries = 4,
    [int]$InitialBackoffMs = 1500
  )
  $attempt = 0
  $backoff = $InitialBackoffMs
  Push-Location -LiteralPath $WorkingDir
  try {
    while ($true) {
      $attempt++
      $errFile = [System.IO.Path]::GetTempFileName()
      try {
        if ($Model) {
          $raw = & $NodeExe $GeminiJs -m $Model -p $PromptText -o json --approval-mode plan 2>$errFile
        } else {
          $raw = & $NodeExe $GeminiJs -p $PromptText -o json --approval-mode plan 2>$errFile
        }
        $stdout = if ($raw -is [array]) { [string]::Join("`n", $raw) } else { [string]$raw }
        $errText = if (Test-Path $errFile) { Get-Content -LiteralPath $errFile -Raw } else { "" }
        if ([string]::IsNullOrWhiteSpace($stdout)) {
          $msg = "empty stdout from gemini.js; stderr: $($errText.Substring(0, [Math]::Min(800, [Math]::Max($errText.Length, 1))))"
          if ($attempt -lt $MaxRetries -and (Test-RetryableGeminiFailure -Message "$msg $errText" -ExitCode 1)) {
            Start-Sleep -Milliseconds $backoff
            $backoff = [math]::Min($backoff * 2, 60000)
            continue
          }
          throw $msg
        }
        return $stdout
      } finally {
        Remove-Item -LiteralPath $errFile -ErrorAction SilentlyContinue
      }
    }
  } finally {
    Pop-Location
  }
}

function New-BenchmarkRunMetadata {
  param(
    [string]$RepoRoot = $null
  )
  $git = $null
  if ($RepoRoot -and (Test-Path (Join-Path $RepoRoot ".git"))) {
    try {
      Push-Location $RepoRoot
      $git = (& git rev-parse --short HEAD 2>$null) | Select-Object -First 1
    } catch { }
    finally { Pop-Location }
  }
  return [PSCustomObject]@{
    gemini_cli_version = Get-GeminiVersionLine
    node_version       = (& node --version 2>$null)
    auth_mode_hint     = Get-AuthModeHint
    run_id             = [guid]::NewGuid().ToString("n")
    generated_at       = (Get-Date).ToString("o")
    git_short          = $git
  }
}
