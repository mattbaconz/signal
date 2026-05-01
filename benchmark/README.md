# SIGNAL benchmarks

v0.4.0 uses a proof-first benchmark suite. It compares `baseline`, `terse-control`, `caveman-style`, and `signal`, then separates output compression, input compression, skill overhead, and long-session checkpoint savings.

Single entrypoint (from repo root):

```powershell
# Automatic local benchmark: static proof + dry-run live plans
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1

# Automatic live output smoke through Gemini CLI JSON (one scenario by default)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1 -Live

# Full live output benchmark
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\auto-benchmark.ps1 -Live -MaxLiveScenarios 0

# Static proof suite: input compression + skill overhead (no API; safe for CI)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Static

# Output benchmark plan (no API; no writes)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Output -DryRun

# Opt-in live output run through Gemini CLI JSON
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Output -Live -WriteResults

# Input compression fixture gate
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode InputCompress

# Caveman comparison plan using the same arms/schema
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode CompareCaveman -DryRun

# Live Gemini — single-turn chess A/B (needs `gemini` on PATH + auth)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Chess

# Live Gemini — multi-turn long session (extra args forwarded: -Quick, -Smoke, -DelayMs, ...)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode LongSession -Quick
```

You can also **cd** into `benchmark/long-session` or `benchmark/benchmark chess` and run the scripts there.

## CI vs local

| Runner | Network | Default CI |
|--------|---------|------------|
| [`proof-suite.ps1`](proof-suite.ps1) via `-Mode Static` | No | Yes ([`scripts/verify.ps1`](../scripts/verify.ps1)) |
| `proof-suite.ps1 -Category Output -DryRun` | No | Yes |
| `proof-suite.ps1 -Category CompareCaveman -DryRun` | No | Yes |
| `benchmark chess/run_chess_compare.ps1` | Yes (Gemini API) | No |
| `long-session/run_long_session.ps1` | Yes (many sequential calls) | No |

## What to measure

1. **Output compression with controls** — compare `baseline`, `terse-control`, `caveman-style`, and `signal`. This prevents claiming wins that are really just "be brief" wins.
2. **Input compression** — memory/rules/docs shrinkage must pass required-term fidelity gates.
3. **Skill overhead** — canonical `.md` vs `.min.md` loaded instruction surface.
4. **Long agentic sessions** — compare cumulative `tokens_primary_max` and message chars with checkpoint chunks vs growing full history.

All rows use the schema documented in [`docs/benchmark-methodology.md`](../docs/benchmark-methodology.md): `scenario_id`, `arm`, `model`, `input_tokens`, `output_tokens`, `total_tokens`, `chars`, `success`, `fidelity_score`, `timestamp`, `git_sha`.

## Shared library

[`lib/gemini-invoke.ps1`](lib/gemini-invoke.ps1) parses Gemini token stats and retries transient failures. It is used by **long-session** and **chess** runners.

## Layout

| Path | Purpose |
|------|---------|
| [`run.ps1`](run.ps1) | Thin dispatcher: proof modes plus `Chess` / `LongSession` |
| [`proof-suite.ps1`](proof-suite.ps1) | v0.4 proof suite: `Static` / `Output` / `InputCompress` / `SkillOverhead` / `CompareCaveman` |
| [`fixtures/`](fixtures/) | Output and input-compression benchmark fixtures |
| [`results/`](results/) | Checked-in deterministic result snapshots |
| [`lib/`](lib/) | Shared Gemini helpers |
| [`long-session/`](long-session/) | Multi-turn baseline vs chunked CKPT |
| [`benchmark chess/`](benchmark%20chess/) | Single-turn two-folder compare |

## External example harness

An optional external chess harness may live outside this repo; it does not replace **`long-session/`** for cumulative proof.
