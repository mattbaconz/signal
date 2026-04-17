# Karpathy-style coding norms (SIGNAL layer)

Behavioral defaults for **implementation and editing** tasks. They complement SIGNAL’s **output compression** (tiers, templates, checkpoints): compression shapes *what you emit*; these norms shape *how you reason and scope work* before and during edits.

**Tradeoff (from upstream):** bias toward **caution over speed** on non-trivial work; use judgment on trivial one-liners.

## Attribution

Adapted from ideas popularized by Andrej Karpathy on common LLM coding failures (assumptions, bloat, careless edits, weak verification) and from the MIT-licensed project [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (`CLAUDE.md`). This file is a SIGNAL-specific rewrite—not an endorsement by Karpathy or the upstream author.

## 1. Think before coding

**Do not assume. Do not hide confusion. Surface tradeoffs.**

Before implementing:

- State assumptions explicitly; if uncertain, **ask** instead of guessing.
- If multiple interpretations fit, **list them**—do not pick one silently.
- If a simpler approach exists, say so; push back when the request invites overkill.
- If something is unclear, **stop**, name what is unclear, and ask.

**SIGNAL mapping:** use `TMPL:arch` for `{decision}|{tradeoff}|{rec}|[conf]` when comparing options; for ambiguity, a one-line `ALT: a|b|c` list is acceptable in SIGNAL-2+. If the user needs a real clarifying question, ask it—then return to terse replies. If terse output would **hide** material confusion, use `SIGNAL_DRIFT: need clarification on <topic>` instead of guessing.

## 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No extra “flexibility” or configurability unless requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and 50 would do, **simplify**.

**SIGNAL mapping:** keep code blocks and identifiers verbatim (never compress code). Summaries of intent stay in templates / short lines.

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Do not “improve” adjacent code, comments, or formatting unless requested.
- Do not refactor unrelated areas.
- Match existing style even if you would do it differently.
- If you see unrelated dead code, **mention** it—do not delete it unless asked.

Orphans **from your edit**: remove imports / vars / functions **you** made unused. Do not remove pre-existing dead code unless asked.

**Test:** every changed line should trace to the user’s request.

**SIGNAL mapping:** `TMPL:rev` for review-shaped notes; keep diffs minimal in assistant narration.

## 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn tasks into checkable goals:

- “Add validation” → tests for invalid inputs, then make them pass.
- “Fix the bug” → reproduce (test or steps), then fix, then re-verify.
- “Refactor X” → tests pass before and after.

For multi-step work, use a **short** plan with verification hooks:

```text
1. [step] → verify: [check]
2. [step] → verify: [check]
```

**SIGNAL mapping:** plans can be compressed one-liners; do not drop verification on non-trivial tasks. Strong criteria reduce thrash; weak “make it work” invites clarification loops.

## When norms conflict with SIGNAL

- **Norms win** on safety, scope, and honesty (no silent assumptions).
- **SIGNAL wins** on surface form unless hiding confusion would violate (1).
- If you cannot satisfy both, output exactly: `SIGNAL_DRIFT: <one-line reason>` (see core `signal/SKILL.md`).

## How you know it is working

- Smaller diffs; fewer drive-by edits.
- Clarifying questions **before** wrong implementation.
- Simpler first-time code; fewer speculative abstractions.
- Verification tied to stated goals.
