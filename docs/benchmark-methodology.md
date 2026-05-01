# SIGNAL v0.4.0 Benchmark Methodology

SIGNAL benchmarks are proof-first: no compression result counts unless the shorter output preserves technical substance.

## Arms

Every live output benchmark uses the same scenario across four arms:

| Arm | Purpose |
|---|---|
| `baseline` | Normal agent/system prompt. |
| `terse-control` | Explicit "answer concisely" control, so SIGNAL is not compared only against verbose default output. |
| `caveman-style` | Telegraphic/persona-style compression control. This is a fair baseline, not an attack on Caveman. |
| `signal` | Actual SIGNAL skill/defaults. |

## Categories

| Category | Measures | Default |
|---|---|---|
| Output compression | Real model output tokens/chars across coding, debug, review, and architecture prompts | Live opt-in |
| Input compression | Original vs SIGNAL-compressed memory/rules/docs | Static + fixture based |
| Skill overhead | Canonical skill bytes/tokens vs `.min.md` install surface | Static |
| Long-session savings | Cumulative context growth with checkpoints vs full history | Live opt-in |

## Required Row Schema

All benchmark rows use this schema:

```json
{
  "scenario_id": "fix-auth-expiry",
  "arm": "signal",
  "model": "static-char4",
  "input_tokens": 100,
  "output_tokens": 40,
  "total_tokens": 140,
  "chars": 160,
  "success": true,
  "fidelity_score": 1.0,
  "timestamp": "2026-05-01T00:00:00Z",
  "git_sha": "abcdef0"
}
```

## Fidelity Gate

A row can be reported as a win only when:

- Required facts are present.
- Code blocks, inline code, commands, file paths, line numbers, URLs, versions, flags, env vars, quoted errors, and technical terms are unchanged.
- The answer still solves the task.
- The compressed form is understandable to an engineer reading it without hidden context.

If any gate fails, set `success=false` and do not include the row in savings claims.

## Commands

```powershell
# Automatic local benchmark: static proof + dry-run live plans
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1

# Automatic live output smoke through Gemini CLI JSON (one scenario by default)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1 -Live

# Full live output benchmark
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1 -Live -MaxLiveScenarios 0

# No network; safe for CI
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Static

# Dry-run live output plan; no API call and no writes
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Output -DryRun

# Lower-level opt-in live output run through Gemini CLI JSON
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Output -Live -WriteResults

# Input compression fixture gate
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode InputCompress

# Caveman comparison plan with the same arms/schema
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode CompareCaveman -DryRun
```

## Reporting Rules

- Report medians and p10/p90 ranges, not only best cases.
- Separate output, input, skill-overhead, and long-session metrics.
- Note whether numbers are static estimates (`ceil(chars/4)`) or real provider token counts.
- Keep raw JSON results checked in when a README table uses them.
