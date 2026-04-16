# SIGNAL benchmarks

## What to measure

- **Single-turn Q&A** (e.g. chess harness): easy to run, but **SIGNAL-3 checkpointing does not apply**. Expect mixed or negative deltas if you add a long activation prefix every message.
- **Long agentic sessions** (recommended): baseline keeps **full** chat history; SIGNAL-3 periodically **replaces** history with a **CKPT** atom (see `signal/references/checkpoint.md`). Compare **cumulative** tokens over the whole session.

## Gemini CLI

- Prefer `**GEMINI.md`** for default BOOT (see `templates/gemini-GEMINI.md`) instead of repeating a long prefix in every prompt.
- Use `**gemini -o json**` and sum `stats.models.*.tokens.total` only if you accept multi-model overhead; report **median** across multiple runs.
- **Chess single-turn pair** (`benchmark/benchmark chess/`): same prompt, two folders (with/without project `GEMINI.md`), `run_chess_compare.ps1` → `results_chess_compare.json`. See that README for interpretation (output length vs total tokens).

## Long-session harness (Gemini CLI)

See `**long-session/`**:

- `turns.json` — scripted user messages (15 turns; chess-validator scenario).
- `run_long_session.ps1` — runs **baseline** (full transcript every turn) vs **SIGNAL-3** (synthetic `CKPT` block replaces history before turns 6, 11, …). Writes `results_baseline.json`, `results_signal.json`, `results_compare.json`, `RESULTS.md`.
- `run_long_session.ps1 -Quick` — first **5** turns only (smoke test; no CKPT yet).

```powershell
cd benchmark\long-session
.\run_long_session.ps1 -Quick   # fast sanity check
.\run_long_session.ps1          # full 15-turn run (~15–30+ min)
```

## External example harness

A separate chess harness lives at `C:\chess benchmark\` (see `run_all.ps1` there). It complements but does not replace the long-session runner above.