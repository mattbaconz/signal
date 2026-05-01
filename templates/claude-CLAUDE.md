# Merge into your project `CLAUDE.md` (Claude Code)

When SIGNAL is installed as a skill, keep **this block short** so every session gets defaults **without** pasting a long `/signal3` preamble on each message.

**Minimal injection (fewest prompt tokens):** merge only [`claude-CLAUDE.min.md`](claude-CLAUDE.min.md) instead of this file.

---

## SIGNAL session defaults

- Default style for every reply: SIGNAL-3 (terse, no preamble, no hedging, conf [0.0-1.0], auto-ckpt).
- No per-turn prefix is required. Treat `signal3`, `SIGNAL-3`, and `/signal3` as the same reset to S3.
- When the user asks for terse or low-token output, follow the **`signal`** skill and choose the tier based on session shape: prefer `/signal3` as the standard. See the bundle **`README.md`** (section **When to use which tier (canonical)**).
- Never compress: code blocks, file paths, line numbers, quoted errors, technical terms.
- Use `/signal-compress` for memory, rules, and project docs that are too large.

## Coding tasks (Karpathy-inspired norms)

When **implementing or editing code**, follow the **`signal`** skill section *Coding tasks (Karpathy-inspired norms)* and [`karpathy-coding-norms.md`](../references/karpathy-coding-norms.md) in the bundle (assumptions, simplicity, minimal diff, verifiable goals).

---

Remove this section if your project already defines conflicting tone rules.
