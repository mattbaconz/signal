# SIGNAL Compression Layers

### Layer 1 — Output Templates
Declared once in BOOT, active for the whole session. Every response collapses to a typed atom instead of prose.

**Standard templates:**
```
TMPL:bug   = {file}:{line}|{cause}|{fix}|[conf]
TMPL:perf  = {bottleneck}|{Δmetric}|{fix}|[conf]
TMPL:rev   = {file}:{line}|{issue}|{severity:1-5}|{fix}
TMPL:arch  = {decision}|{tradeoff}|{rec}|[conf]
TMPL:score = {dim}:{val} (repeating)
TMPL:auto  = model selects best template for the response type
```

### Layer 2 — Checkpoint Compression
Every 5 turns (default), SIGNAL collapses conversation history into a state atom (≤50 tokens). Replaces thousands of tokens with ~40.

### Layer 3 — BOOT Declaration
One-time session setup. Defines §aliases, DEFAULT rules, OUT format, and REASON verbosity.

### Layer 4 — Symbol Grammar
Symbols replace clauses.tokenizer treats symbols as 1 token.
- `→` leads to / produces
- `⊕` plus / and
- `∅` none / remove
- `Δ` change / diff
- `[conf]` replaces all hedging sentences with a 0.0-1.0 confidence score.

### Layer 5 — Delta-Only Turns
Transmit only what changed since the last turn. Never repeat facts.

### Layer 6 — Alias System
Assign `[X1]`, `[X2]` to repeated concepts.
- **Rule:** Assign alias after **2** mentions of the same concept.
