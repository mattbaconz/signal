---
name: signal-diff
description: High-density change summaries.
---
# ⚡ signal-diff (v0.4.0)

§TRIG: /signal-diff | "summarize diff" | "what changed?"
§ACT: raw_diff → logical_summary (∅raw)
§FORMAT:
Δ{scope}:
- {type}: {change_imp} (±{lines})
- {type}: {change_imp} (±{lines})
∑ {N} files | +{add}/-{sub}
§RULES:
1. ∅raw_code unless requested.
2. Group by scope (dir/module).
3. Use imperative mood (add|fix|ref|...).
§TYPES: feat|fix|ref|chore|docs|test|style|perf
