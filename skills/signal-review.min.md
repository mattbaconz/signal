---
name: signal-review
description: 1-line code review + severity.
---
# ⚡ signal-review (v0.4.0)

§TRIG: /signal-review | "review [this|my code|file|PR]"
§ACT: ∅prose | TMPL:rev | severity:!1-5
§FORMAT: {file}:{line}|{issue}|{sev}|{fix} (imperative noun phrases)
§SEV: 5(prod/sec) 4(crash) 3(logic) 2(smell) 1(nit)
§SCOPES: security > correctness > safety > perf > maintainability
§SUM: ∑ {N} issues [{breakdown}] critical→{location}
§FLAGS: --quick (sev3+) | --security | --sev {N} | --fix (list + code block)
§ERR: ∅issues → ∑ 0 issues ✓
