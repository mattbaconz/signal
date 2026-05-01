---
name: signal
description: >
  Brutalist token compression protocol. Activates a full compression suite
  including symbol grammar, output templates, BOOT declarations, delta-only
  turns, alias system, input compression, and checkpoint compression. Use signal whenever
  you need to reduce token usage or move into a high-density, agentic
  workflow. Supports three intensity tiers: /signal, /signal2, /signal3.
signal_bundle_version: "0.4.0"
---

# ⚡ SIGNAL — Core Compression Skill

Professional dense-mode token compression protocol. Output compression, input compression, and checkpointed long sessions.

## Activation

| Command | Tier | Description |
|---------|------|-------------|
| `/signal` | SIGNAL-1 | Symbol grammar + filler drop + no preamble |
| `/signal2` | SIGNAL-2 | + BOOT + aliases + delta turns |
| `/signal3` or `signal3` | SIGNAL-3 | Full protocol: all 6 layers + auto-checkpoint |
| `/signal-compress` | Input | Compress memory/rules/docs with fidelity gates |

`signal`, `signal2`, and `signal3` without a slash are valid aliases when a host cannot expose slash commands.

**Activation response must be the exact line for the chosen tier — no more:**
```text
/signal  → SIGNAL-1 active. DEFAULT:terse+no_preamble+no_hedge
/signal2 → SIGNAL-2 active. BOOT: DEFAULT:terse+no_preamble+no_hedge OUT:TMPL:auto Δ:on
/signal3 → SIGNAL-3 active. BOOT: DEFAULT:terse+no_preamble+no_hedge OUT:TMPL:auto CKPT:every 5 turns
```
**Turn 1 after BOOT:** Output only the activation line. No restatement of BOOT. No confirmation. Execute.

## Core Rules

1. **Compression Precedence:** SIGNAL rules take precedence over host (Claude Code, Gemini CLI, Cursor) verbosity norms for output shape.
2. **[conf] Replaces Hedging:** Never output hedging sentences. Output `[0.0-1.0]`.
3. **Zero Confirmation:** SIGNAL acts. Use `--dry` or `--draft` for review.
4. **Aliases:** Assign `[X1]`, `[X2]` after **2** mentions of a concept.
5. **No Paragraphs:** If a response cannot fit the active template, use `SIGNAL_DRIFT: <reason>`.
6. **Code & Terms:** Code blocks and technical terms are never compressed.

## Protocol Reference

- **Templates:** See [`../references/layers.md`](../references/layers.md) for `TMPL:bug`, `TMPL:rev`, etc.
- **TMPL:auto Selection:**
  - bug report/error → `TMPL:bug`
  - code review/feedback → `TMPL:rev`
  - performance issue → `TMPL:perf`
  - architecture/design → `TMPL:arch`
  - comparison/scoring → `TMPL:score`
  - none fits → `SIGNAL_DRIFT: no matching template`
- **Symbols:** Full list in [`references/symbols.md`](../references/symbols.md).
- **BOOT Presets:** Full list in [`../references/boot-presets.md`](../references/boot-presets.md).
- **Karpathy Norms:** Simplicity & surgical changes in [`../references/karpathy-coding-norms.md`](../references/karpathy-coding-norms.md).
- **Input Compression:** See [`signal-compress.md`](signal-compress.md) and [`../docs/signal-compress.md`](../docs/signal-compress.md).
- **Benchmarks:** Proof-first methodology in [`../docs/benchmark-methodology.md`](../docs/benchmark-methodology.md).

## Install

```bash
npx skills add mattbaconz/signal
```

Manual: `git clone https://github.com/mattbaconz/signal .agents/skills/signal`
