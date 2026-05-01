---
name: signal-compress
description: >
  Compress memory files, prompts, rules, handoff notes, and project docs into
  SIGNAL-shaped prompt-token-friendly text while preserving code, paths,
  identifiers, errors, versions, and technical terms. Use when user types
  /signal-compress, "compress this memory", "shrink this prompt", "compress
  project rules", or asks to reduce input/prompt tokens.
signal_bundle_version: "0.4.0"
---

# ⚡ signal-compress — Input Compression

Reduce prompt tokens before the agent reads the same prose every turn. Preserve technical substance; compress prose only.

---

## Invocation Triggers

Activate when user says any of:
- `/signal-compress`
- `"compress this memory"`, `"shrink this prompt"`, `"compress project rules"`
- `"compress CLAUDE.md"`, `"compress GEMINI.md"`, `"compress AGENTS.md"`
- `"reduce input tokens"`, `"make this rules file shorter"`

Targets can be memory files, project rules, prompts, handoff notes, README-like prose, or pasted text.

---

## Behavior

1. **Back up first** when a file path is provided:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\signal-compress.ps1 -Path .\GEMINI.md
   ```
   The helper only creates `<name>.original.<ext>` and prints the prompt/review steps.

2. **Compress prose only** using [`templates/signal-compress-prompt.md`](../templates/signal-compress-prompt.md).

3. **Protect exact tokens**:
   - Fenced code blocks and shell commands
   - Inline code, file paths, line numbers, URLs
   - Quoted errors, stack traces, logs
   - Version numbers, dates, identifiers, flags, env vars
   - Technical terms and proper nouns

4. **Diff review** against the original. Reject the rewrite if protected tokens changed, facts disappeared, or instructions became ambiguous.

5. **Report measured savings** with this shape:
   ```text
   signal-compress|target=GEMINI.md|chars 2400→980|est_tok 600→245|save 59%|fidelity pass
   ```

---

## Output Rules

When returning compressed text, output only the compressed file contents. No preamble, no summary, no wrapper fence.

When reporting a completed file workflow, use one line:
```text
signal-compress|target={path}|chars {old}→{new}|est_tok {old}→{new}|save {pct}%|fidelity {pass|fail}
```

If compression is unsafe:
```text
SIGNAL_DRIFT: <one-line reason>
```

---

## Fidelity Gate

A compression win counts only when:
- Every protected token is unchanged.
- All actionable instructions remain present.
- Headings stay navigable.
- Any code, paths, flags, errors, and version numbers remain verbatim.
- The compressed file can replace the original without changing agent behavior.

---

## Related

- [`docs/signal-compress.md`](../docs/signal-compress.md)
- [`docs/benchmark-methodology.md`](../docs/benchmark-methodology.md)
- [`scripts/signal-compress.ps1`](../scripts/signal-compress.ps1)
