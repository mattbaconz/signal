# Gemini CLI — chess single-turn comparison

**Purpose:** Run the **same** user prompt from [`prompt.txt`](prompt.txt) in two project folders (cold start each time).

## Folder pairs (`-Pair`)

| `-Pair` | Folders | Role |
|---------|---------|------|
| **`Default`** (default) | [`chess baseline (no signal)`](chess%20baseline%20(no%20signal)/) vs [`chess signal (signal skill used)`](chess%20signal%20(signal%20skill%20used)/) | No project `GEMINI.md` vs SIGNAL-style project file — shows **prompt vs output** tradeoff when adding instructions. |
| **`EqualContext`** | [`chess equal verbose`](chess%20equal%20verbose/) vs [`chess equal signal`](chess%20equal%20signal/) | **Both** have short `GEMINI.md` (verbose control vs SIGNAL minimal) — **fairer** comparison of **reply style** with closer prompt parity. |

**Prerequisites**

1. Install SIGNAL skills (once): `npx skills add mattbaconz/signal -y -g`
2. [Gemini CLI](https://github.com/google-gemini/gemini-cli) on `PATH` (`gemini --version`)

**Run**

```powershell
cd benchmark\benchmark chess
.\run_chess_compare.ps1
.\run_chess_compare.ps1 -Pair EqualContext
.\run_chess_compare.ps1 -Model <model-id>   # optional; default = CLI default model
```

The script invokes `node …/gemini.js -p @prompt.txt -o json --approval-mode plan` once per folder (separate cold starts), parses `stats` from JSON, and writes:

- **`Default`:** `results_chess_compare.json`
- **`EqualContext`:** `results_chess_equal_compare.json`

**429 / capacity**

If Google returns **429** (*No capacity* / *RESOURCE_EXHAUSTED*), wait and **retry later**, or pass **`-Model`** to a different model your CLI supports. The script does not auto-retry (keeps runs deterministic).

**Interpreting tokens**

- **`tokens_primary_max`**: max of `stats.models.*.tokens.total` for that turn (avoids double-counting router vs main when multiple models appear), same helper as `benchmark/long-session/run_long_session.ps1` in a **full repo clone** (that path may be absent in shallow checkouts).
- **`tokens.total`** mixes **prompt/input** and **generation**. Compare **`stats.models.*.tokens.prompt`** separately from **shorter assistant text**. See **[`docs/token-metrics.md`](../../docs/token-metrics.md)**.
- **Cumulative proof** (history + checkpoints) is **`benchmark/long-session/`** in a full clone — not this single-turn harness.

**Verified numbers**

A paired run is archived in [`results_chess_compare.json`](results_chess_compare.json) (`verified_paired_run`). It shows **much shorter assistant text** with SIGNAL in the **Default** pair, while **`tokens.total` can still rise** because **prompt** grew — read the `interpretation` field and [`docs/token-metrics.md`](../../docs/token-metrics.md).
