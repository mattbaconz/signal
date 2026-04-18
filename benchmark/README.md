# SIGNAL benchmarks

## What to measure (priority)

1. **Long agentic sessions (primary proof)** — baseline keeps **full** chat history; SIGNAL-3 periodically **replaces** history with a **CKPT** atom (see `references/checkpoint.md`). Compare **cumulative** tokens over the whole session. **In a full clone of this repo**, use **`benchmark/long-session/`** (see on-disk `README.md` there).

2. **Single-turn Q&A** (e.g. chess harness) — easy to run, but **SIGNAL-3 checkpointing does not apply**. Expect mixed or negative **net** `tokens.total` if one arm loads much more project context than the other. Read **[`docs/token-metrics.md`](../docs/token-metrics.md)** before interpreting totals.

## Long-session harness (Gemini CLI) — start here

After cloning, open **`benchmark/long-session/README.md`** and run:

```powershell
cd benchmark\long-session
.\run_long_session.ps1 -Quick   # fast sanity check (5 turns)
.\run_long_session.ps1          # full 15-turn run (~15–30+ min)
```

- `turns.json` — scripted user messages (15 turns; chess-validator scenario).
- `run_long_session.ps1` — baseline (full transcript every turn) vs SIGNAL-3 (synthetic `CKPT` replaces history before turns 6, 11, …). Writes `results_baseline.json`, `results_signal.json`, `results_compare.json`, `RESULTS.md`.

## Gemini CLI — chess single-turn pair

Prefer `**GEMINI.md**` for default BOOT (see `templates/gemini-GEMINI.md`) instead of repeating a long prefix in every prompt.

- **`benchmark/benchmark chess/`** — same `prompt.txt`, two folder pairs, `run_chess_compare.ps1` → JSON results. See that folder’s **README** for `-Pair`, `-Model`, and **429** handling.
- Use `**gemini -o json**` and interpret **`prompt`** vs **`tokens.total`** per [`docs/token-metrics.md`](../docs/token-metrics.md).

## External example harness

A separate chess harness lives at `C:\chess benchmark\` (see `run_all.ps1` there). It complements but does not replace the long-session runner above.
