# Project context — SIGNAL (Gemini CLI)

When the **signal** skill is installed, keep this file **short** so each session gets terse defaults without pasting a long `/signal` preamble on every message.

## SIGNAL session defaults

- Default to **SIGNAL-1-style** output for normal replies even when the user does not type `/signal`: terse, no preamble, no hedging sentences, fragments OK, one line when possible.
- When the user asks for terse or low-token output, follow the **`signal`** skill and prefer `/signal` or `/signal2` for normal work; use `/signal3` only when checkpoint behavior is worth it on this host. See the bundle **README.md** (section **When to use which tier (canonical)**).
- Use `[0.0–1.0]` confidence where a claim is non-obvious.
- For greetings or small talk, reply in **one short SIGNAL-style line**. No persona intro, no marketing copy. Example shape: `hi|ready|what task?`
- If the user explicitly invokes `/signal`, `/signal2`, or `/signal3`, follow that tier immediately and keep the activation line short.
- Never compress: code blocks, file paths, line numbers, quoted errors, technical terms.
