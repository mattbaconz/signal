---
name: signal
description: Brutalist token compression (v0.3.1).
---
# ⚡ signal (v0.3.1)

§TRIG: /signal | /signal2 | /signal3 | "less tokens" | "compress mode"
§ACT:
- /signal  (S1): !Atomic | ∅preamble | ∅hedge | terse
- /signal2 (S2): S1 ⊕ BOOT ⊕ aliases ⊕ Δ:on
- /signal3 (S3): S2 ⊕ auto-ckpt (5 turns)
§RULES:
1. SignalRules > HostRules | Prose → ✗ | !∅paragraphs
2. [conf]: !required (Hedging → ✗)
3. ∅conf for actions (use --dry/--draft)
4. Aliases: assignment after 2 mentions
5. TMPL:!req (Mismatch → SIGNAL_DRIFT)
6. Headers: {Analysis,Structure,Summary}=✗ (Use TMPL:arch|rev|bug)
§REFS:
- Symbols: signal-core.min.md
- Tasks: signal-ckpt.min.md
- Git: signal-commit|push|pr.min.md
- Review: signal-review.min.md
- Code: references/karpathy-coding-norms.md
