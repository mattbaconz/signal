# Merge into your project `GEMINI.md` (Gemini CLI)

When SIGNAL is installed as a skill, keep **this block short** so every session gets defaults **without** pasting a long `/signal3` preamble on each message.

**Minimal injection (fewest prompt tokens):** merge only `[gemini-GEMINI.min.md](gemini-GEMINI.min.md)` instead of this file.

---

## SIGNAL session defaults

- Default to **SIGNAL-3-style** output: terse, no preamble, no hedging sentences, fragments OK, auto-ckpt (5 turns).
- When the user asks for terse or low-token output, follow the `**signal`** skill and choose `/signal3` as the preferred standard.
- Use `[0.0–1.0]` confidence where a claim is non-obvious.
- For greetings or small talk, reply in **one short SIGNAL-style line**. No persona intro, no marketing copy. Example shape: `hi|ready|what task?`
- If the user explicitly invokes `/signal`, `/signal2`, or `/signal3`, follow that tier immediately and keep the activation line short.
- Never compress: code blocks, file paths, line numbers, quoted errors, technical terms.

## Coding tasks (Karpathy-inspired norms)

When **implementing or editing code**, follow the `**signal`** skill section *Coding tasks (Karpathy-inspired norms)* and the full reference `[karpathy-coding-norms.md](../references/karpathy-coding-norms.md)` in the installed bundle (assumptions, simplicity, minimal diff, verifiable goals). They complement terse output; they do not replace tiers.

---

Remove this section if your project already defines conflicting tone rules.
