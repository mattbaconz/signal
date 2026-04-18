# Merge into your project `CLAUDE.md` (Claude Code)

When SIGNAL is installed as a skill, keep **this block short** so every session gets defaults **without** pasting a long `/signal3` preamble on each message.

**Minimal injection (fewest prompt tokens):** merge only [`claude-CLAUDE.min.md`](claude-CLAUDE.min.md) instead of this file.

---

## SIGNAL session defaults

- When the user asks for terse or low-token output, follow the **`signal`** skill and choose the tier based on session shape: prefer `/signal` or `/signal2` for normal work, and use `/signal3` only when checkpoint behavior is worth it on this host. See the bundle **`README.md`** (section **When to use which tier (canonical)**).
- Default style: terse, no preamble, no hedging sentences — use `[0.0–1.0]` confidence where a claim is non-obvious.
- Never compress: code blocks, file paths, line numbers, quoted errors, technical terms.

## Coding tasks (Karpathy-inspired norms)

When **implementing or editing code**, follow the **`signal`** skill section *Coding tasks (Karpathy-inspired norms)* and [`karpathy-coding-norms.md`](../references/karpathy-coding-norms.md) in the bundle (assumptions, simplicity, minimal diff, verifiable goals).

---

Remove this section if your project already defines conflicting tone rules.
