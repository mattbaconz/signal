---
name: signal-search
description: High-density search/grep summaries.
---
# ⚡ signal-search (v0.3.0)

§TRIG: /signal-search | "find [this|pattern]" | "search for [x]"
§ACT: raw_search → summarized_results (∅raw)
§FORMAT:
§PATTERN: {regex}
§RESULTS (⊂{dir}):
- {file}:{line} ⊕ {context_snippet}
- {file}:{line} ⊕ {context_snippet}
∑ {N} matches in {M} files.
§RULES:
1. Snippet: max 40c, ∅filler.
2. Group by importance (core logic > tests > config).
3. If >20 matches, collapse into: "{dir} ({count} matches)".
