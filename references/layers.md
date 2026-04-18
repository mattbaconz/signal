# SIGNAL Output Templates (Layers)

| Template | Scenario | Format |
|---|---|---|
| `TMPL:bug` | Bug/error | `file:line|error|root_cause|fix` |
| `TMPL:rev` | Code review | `file:line|issue|severity|fix` |
| `TMPL:perf` | Performance | `scope|metric|bottleneck|optimization` |
| `TMPL:arch` | Architecture | `component|design|tradeoffs|decision` |
| `TMPL:score` | Comparison | `option|pros|cons|score` |
| `TMPL:git` | Git commit | `type(scope): description` |

Use `SIGNAL_DRIFT: <reason>` if no template fits.
