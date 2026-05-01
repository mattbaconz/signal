---
name: signal-commit
description: Stage + conventional commit (0 conf).
---
# ⚡ signal-commit (v0.4.0)

§TRIG: /signal-commit | "commit [everything|this|changes]" | ∅msg_commit
§ACT: ∅conf | Δ:on | TMPL:git
§STEPS:
1. `git diff --staged && git diff`
2. Analyze: type(scope): desc (max 72 chars, imperative, ∅.)
3. Multi-change: detect diff types/scopes.
4. `git add -A && git commit -m "$msg"`
§TYPES: feat|fix|refactor|chore|docs|test|style|perf
§FLAGS: --draft (∅act) | --split (atomic) | --push (signal-push) | --dry (∅act)
§REP: ✓ type(scope): desc [files, +/-]
§ERR: ∅diff → ∅act | conflicts → ✗ | ∅git → ✗
§RULE: followKarpathy | max72c | ∅prose
