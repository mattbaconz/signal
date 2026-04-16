# Token metrics (how to read SIGNAL vs “total tokens”)

SIGNAL changes **assistant output shape** and, in SIGNAL-3, **how much chat history** you carry. Hosts and APIs report different numbers; mixing them causes confusion (e.g. “totals went up” when replies got shorter).

## Three things to separate

1. **Prompt / input** — Text the model **reads** for this turn: system instructions, project `GEMINI.md` / `CLAUDE.md`, tool definitions, **skills metadata**, and the **user message**. Adding a thicker `GEMINI.md` **increases** this.

2. **Generation / output** — The **assistant reply** (what SIGNAL usually shortens: templates, symbols, `[conf]`, fewer paragraphs).

3. **History** — Prior turns in the thread. This is where **SIGNAL-3** and **checkpoints** (`CKPT`) target savings: replacing a long transcript with a small state atom when the host allows it.

## Why `tokens.total` can go up when SIGNAL “works”

On a **single cold turn**, you might add **project instructions** (SIGNAL defaults in `GEMINI.md`) while also getting a **shorter answer**. **Prompt** tokens rise; **output** tokens fall. Summed **`tokens.total`** (as some CLIs report it) can **increase** if the prompt delta is larger than the output savings.

That is **not** a failure of “output compression” — it is a **measurement scope** issue. Compare **prompt** and **output** separately when possible (e.g. Gemini CLI `stats` in `-o json`).

## What to use as “proof” for SIGNAL’s design

- **Cumulative / multi-turn:** The primary story is **history + repeated output shape**. In a **full clone** of this repo, run `benchmark/long-session/run_long_session.ps1` (see on-disk `benchmark/long-session/README.md`). It compares baseline transcript growth vs SIGNAL-3-style checkpoint chunks.

- **Single-turn (e.g. chess harness):** Useful for **reply length** and **style**, not as a universal net-token score. See [`benchmark/benchmark chess/README.md`](../benchmark/benchmark%20chess/README.md). For **fairer** output-only comparison when both arms have project `GEMINI.md`, use `run_chess_compare.ps1 -Pair EqualContext`.

## Reducing input tokens

Output compression alone cannot hide a 200-line `GEMINI.md`. To shrink **prompt**:

- Default to [`templates/gemini-GEMINI.min.md`](../templates/gemini-GEMINI.min.md) / [`templates/claude-CLAUDE.min.md`](../templates/claude-CLAUDE.min.md) for always-on context.
- For long project memory or notes, rewrite with [`docs/signal-compress.md`](signal-compress.md) (Caveman-compress-style workflow: backup, rewrite, diff review).

## Further reading in this repo

- [README.md — Maximize token savings](../README.md#maximize-token-savings) — practical knobs.
- [README.md — Evidence](../README.md#evidence-what-we-measure) — what we claim and what we do not.
- [templates/gemini-GEMINI.min.md](../templates/gemini-GEMINI.min.md) — thinnest always-on Gemini defaults.
- [docs/signal-compress.md](signal-compress.md) — shrink `GEMINI.md` / notes.
