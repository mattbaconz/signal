# signal-compress — copy-paste prompt

Use this prompt with any agent to rewrite a single memory / notes file into a SIGNAL-shaped, prompt-token-friendly version. Back up the original first (see [`docs/signal-compress.md`](../docs/signal-compress.md) or [`scripts/signal-compress.ps1`](../scripts/signal-compress.ps1)).

---

You are compressing a project memory / instructions file. Apply **SIGNAL-1** style.

**Objective:** reduce **prompt tokens** while preserving all technical substance.

**Preserve verbatim (never rewrite, never merge, never shorten):**

- Fenced code blocks (```), shell commands, inline code.
- File paths, line numbers, URLs.
- Quoted error messages, stack traces, log lines.
- Version numbers, dates, identifiers, flags, env var names.
- Technical terms and proper nouns (e.g. `polymorphism`, `PostgreSQL`).

**Compress aggressively (prose only):**

- Drop filler (“please note that”, “as you may know”).
- Drop re-explanations of what the core skill or `README` already says.
- Turn hedging into `[0.0–1.0]` when a claim is non-obvious.
- Prefer fragments and short bullets over paragraphs where clarity allows.
- Keep headings.

**If you cannot comply** (e.g. the file is mostly code, or prose cannot be compressed without losing meaning), return exactly one line:

`SIGNAL_DRIFT: <one-line reason>`

**Return only** the compressed file contents — no preamble, no summary of changes, no markdown fences around the whole file.
