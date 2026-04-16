# signal-compress: shrink project memory and docs

SIGNAL mainly reduces **assistant output**. This page covers the other side: **what the host reads every session** — long `GEMINI.md`, `CLAUDE.md`, project notes. If those grow, **prompt tokens** go up even when replies are terse.

This is conceptually similar to Caveman’s **`caveman-compress`** (rewrite memory files so the model reads fewer tokens). SIGNAL keeps it as a **documented workflow** rather than a one-shot binary: backup the original, rewrite with SIGNAL-1 rules, diff review, commit.

## When to use

- Your project `GEMINI.md` / `CLAUDE.md` has drifted past ~30–50 lines of prose.
- Long handover notes or onboarding docs that the agent loads every turn.
- You already use [`templates/gemini-GEMINI.min.md`](../templates/gemini-GEMINI.min.md) and still have thick **project-specific** sections worth trimming.

## Preservation rules (do not compress)

Same list as core SIGNAL:

- Fenced code blocks, commands, shell snippets — **verbatim**.
- File paths, line numbers, quoted error strings — **verbatim**.
- Version numbers, dates, identifiers, technical terms.

Compress **prose only**: remove hedging, examples that repeat the rule, and re-explanations. Keep headings; shorten bullets.

## Workflow

1. **Back up** the original next to the file. Example: `signal-compress.ps1 -Path GEMINI.md` → writes `GEMINI.original.md`.
2. **Run the prompt** from [`templates/signal-compress-prompt.md`](../templates/signal-compress-prompt.md) against the file (your host agent, or any LLM you prefer).
3. **Diff review** the rewrite vs the `.original.md` copy. Reject if code/paths/errors were altered.
4. **Commit** only if the rewrite passes review.

## Example target sizes

- Project `GEMINI.md`: aim for ≤ ~15 lines of prose + preserved blocks.
- Long notes: drop paragraphs that repeat what the core skill or `README` already states.
- Convert prose checklists into **fragments** where clarity allows.

## Caveats

- Rewrites can drift. Always keep the `.original.md` until the compressed file has been used for a real session.
- Do **not** compress auto-generated files (schema, changelog, generated indexes).
- Do not run an API-based rewrite over files that contain secrets.

## Related

- [`docs/token-metrics.md`](token-metrics.md) — why input tokens matter even when replies shrink.
- [`templates/gemini-GEMINI.min.md`](../templates/gemini-GEMINI.min.md) / [`templates/claude-CLAUDE.min.md`](../templates/claude-CLAUDE.min.md) — thin always-on defaults.
- [`scripts/signal-compress.ps1`](../scripts/signal-compress.ps1) — backup helper (see header for usage).
