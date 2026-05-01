---
name: signal-compress
description: Compress memory/rules/prompts/docs; preserve exact technical tokens.
---
# ⚡ signal-compress (v0.4.0)

§TRIG: /signal-compress | "compress memory" | "shrink prompt" | "compress AGENTS.md|CLAUDE.md|GEMINI.md" | "reduce input tokens"
§GOAL: input_tok↓ | substance=exact | prose_only
§FLOW:
1. file? backup via `scripts/signal-compress.ps1 -Path <file>`
2. Apply `templates/signal-compress-prompt.md`
3. Diff original↔compressed
4. Accept only if fidelity=pass
§PROTECT: code_blocks | commands | inline_code | paths | line# | URLs | errors | logs | versions | dates | ids | flags | env | tech_terms
§COMPRESS: filler | repeats | hedge→[conf] | long prose→fragments | keep headings
§REP: `signal-compress|target=<path>|chars a→b|est_tok a→b|save n%|fidelity pass`
§ERR: `SIGNAL_DRIFT: <reason>`
§RULE: wins count only if protected tokens unchanged
