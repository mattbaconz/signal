# signal-compress: shrink project memory and docs

SIGNAL reduces **assistant output** and **loaded input**. This page covers the input side: what the host reads every session — long `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`, project rules, handoff notes, and prompts. If those grow, prompt tokens go up even when replies are terse.

In v0.4.0 this is a first-class skill: [`skills/signal-compress.md`](../skills/signal-compress.md). It is conceptually similar to Caveman's `caveman-compress`, but SIGNAL treats fidelity as the gate: shorter text counts only when protected technical tokens and instructions survive unchanged.

## When to use

- Your project `GEMINI.md` / `CLAUDE.md` / `AGENTS.md` has drifted past ~30-50 lines of prose.
- Long handoff notes or onboarding docs that the agent loads every turn.
- You already use [`templates/gemini-GEMINI.min.md`](../templates/gemini-GEMINI.min.md) and still have thick **project-specific** sections worth trimming.

## Preservation rules

Never compress:

- Fenced code blocks, commands, shell snippets.
- Inline code, file paths, line numbers, URLs.
- Quoted error strings, stack traces, logs.
- Version numbers, dates, identifiers, flags, env vars.
- Technical terms and proper nouns.

Compress prose only: remove hedging, examples that repeat the rule, and re-explanations. Keep headings; shorten bullets.

## Workflow

1. **Back up** the original next to the file. Example: `signal-compress.ps1 -Path GEMINI.md` writes `GEMINI.original.md`.
2. **Run the prompt** from [`templates/signal-compress-prompt.md`](../templates/signal-compress-prompt.md) against the file.
3. **Diff review** the rewrite vs the `.original.md` copy. Reject if protected tokens changed.
4. **Commit** only if the rewrite passes review.
5. **Report** savings in the one-line format from `/signal-compress`.

## Example target sizes

- Project `GEMINI.md`: aim for <= ~15 lines of prose plus preserved blocks.
- Long notes: drop paragraphs that repeat what the core skill or README already states.
- Convert prose checklists into fragments where clarity allows.

## Caveats

- Rewrites can drift. Keep the `.original.md` until the compressed file has been used for a real session.
- Do not compress auto-generated files.
- Do not run an API-based rewrite over files that contain secrets.

## Related

- [`docs/benchmark-methodology.md`](benchmark-methodology.md) — fidelity gates and benchmark schema.
- [`docs/token-metrics.md`](token-metrics.md) — why input tokens matter even when replies shrink.
- [`templates/gemini-GEMINI.min.md`](../templates/gemini-GEMINI.min.md) / [`templates/claude-CLAUDE.min.md`](../templates/claude-CLAUDE.min.md) — thin always-on defaults.
- [`scripts/signal-compress.ps1`](../scripts/signal-compress.ps1) — backup helper.
