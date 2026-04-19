# SIGNAL benchmarks

Single entrypoint (from repo root):

```powershell
# Static: char/4 heuristic + skill sizes (no API; safe for CI)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Static

# Live Gemini — single-turn chess A/B (needs `gemini` on PATH + auth)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Chess

# Live Gemini — multi-turn long session (extra args forwarded: -Quick, -Smoke, -DelayMs, …)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode LongSession -Quick
```

You can also **cd** into `benchmark/long-session` or `benchmark/benchmark chess` and run the scripts there (useful for `-Pair EqualContext`, `-FixtureDir`, etc.).

## CI vs local

| Runner | Network | Default CI |
|--------|-----------|------------|
| [`scripts/benchmark.ps1`](../scripts/benchmark.ps1) via `-Mode Static` | No | Yes ([`scripts/verify.ps1`](../scripts/verify.ps1)) |
| `benchmark chess/run_chess_compare.ps1` | Yes (Gemini API) | No |
| `long-session/run_long_session.ps1` | Yes (many sequential calls) | No |

## What to measure (priority)

1. **Long agentic sessions (primary proof)** — baseline keeps **full** chat history; SIGNAL-3 **chunked** runs use a **synthetic CKPT** in the first message of each chunk (protocol benchmark — not the same as typing `/signal3` in chat). Compare **cumulative** `tokens_primary_max` and **message chars**. See **[`long-session/README.md`](long-session/README.md)** for metrics, `-Smoke` (6 turns), `-FixtureDir`, `-DelayMs`, and **429** spacing.

2. **Single-turn Q&A** (chess harness) — fast; **SIGNAL-3 checkpointing does not apply**. Use **`-Pair EqualContext`** for fair `GEMINI.md` loading. Read **[`docs/token-metrics.md`](../docs/token-metrics.md)** before interpreting `tokens.total` vs `prompt`.

## Shared library

[`lib/gemini-invoke.ps1`](lib/gemini-invoke.ps1) — token parsing (`primary_max`, prompt, output estimate), JSON parse, stdin and node-bundle invoke with **retry on 429 / quota / transient**, run metadata (CLI version, auth hint, git short hash). Used by **long-session** and **chess** runners.

## Layout

| Path | Purpose |
|------|---------|
| [`run.ps1`](run.ps1) | Thin dispatcher: `Static` / `Chess` / `LongSession` |
| [`lib/gemini-invoke.ps1`](lib/gemini-invoke.ps1) | Shared Gemini helpers |
| [`long-session/`](long-session/) | Multi-turn baseline vs chunked CKPT |
| [`benchmark chess/`](benchmark%20chess/) | Single-turn two-folder compare |

## External example harness

An optional external chess harness may live outside this repo; it does not replace **`long-session/`** for cumulative proof.
