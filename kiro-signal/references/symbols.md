# SIGNAL Symbol Grammar

| Symbol | Meaning | Example |
|---|---|---|
| `→` | causes / produces / results in | `nullref→crash` |
| `⊕` | combined with / and / plus | `auth⊕session` |
| `∅` | none / remove / empty | `cache=∅` |
| `Δ` | change / diff / update | `Δ+cache→~5ms` |
| `!` | critical / must / required | `!fix before deploy` |
| `?` | uncertain / verify / check | `race?` |
| `~` | approx / similar to | `~200ms` |
| `∴` | therefore / so / thus | `∴ add guard` |
| `⊂` | subset / part of / in | `auth⊂middleware` |
| `⊥` | conflicts / blocks | `X2⊥X3` |
| `✓` | complete / ok | `cache✓` |
| `✗` | failed / error | `test✗` |
| `∑` | summary / total | `∑ 3 issues` |
| `§` | alias declaration | `§c=codebase` |
| `[n]` | confidence 0.0–1.0 | `[0.95]` |

Full protocol in `skills/signal-core.min.md`.
