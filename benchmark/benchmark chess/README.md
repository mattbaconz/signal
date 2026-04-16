# Gemini CLI — chess single-turn comparison

**Purpose:** Run the **same** user prompt from [`prompt.txt`](prompt.txt) in two empty project folders:

| Folder | Project `GEMINI.md` | Intended behavior |
|--------|---------------------|-------------------|
| [`chess baseline (no signal)`](chess%20baseline%20(no%20signal)/) | None | More “normal” verbose assistant tone |
| [`chess signal (signal skill used)`](chess%20signal%20(signal%20skill%20used)/) | Yes (SIGNAL defaults) | Terse, SIGNAL-shaped replies |

**Prerequisites**

1. Install SIGNAL skills (once): `npx skills add mattbaconz/signal -y -g`
2. [Gemini CLI](https://github.com/google-gemini/gemini-cli) on `PATH` (`gemini --version`)

**Run**

```powershell
cd benchmark\benchmark chess
.\run_chess_compare.ps1
```

The script invokes:

`gemini -p <prompt.txt> -o json --approval-mode plan`

once per folder (separate cold starts), parses `stats` from JSON, and writes `results_chess_compare.json`.

**Interpreting tokens**

- **`tokens_primary_max`**: max of `stats.models.*.tokens.total` for that turn (avoids double-counting router vs main when multiple models appear), same helper as [`../long-session/run_long_session.ps1`](../long-session/run_long_session.ps1).
- **`tokens.total`** mixes **prompt/input** and **generation** in one number. For a fair read, compare **`stats.models.*.tokens.prompt`** (or equivalent **input** fields) separately from **shorter assistant text** (output). SIGNAL can **lower output** while **`tokens.total` rises** if **prompt** grew (e.g. project `GEMINI.md` + skills).
- Single-turn totals are dominated by **system + tools + first message**; expect **mixed** deltas vs baseline. For SIGNAL-3 and cumulative savings, prefer [`../long-session/`](../long-session/).

**Failures**

If the API returns **429** (*no capacity* / *rate limit*) or other errors, the script records `error` in the JSON and exits non-zero. Retry later or another model/day.

**Verified numbers**

A successful paired run is archived in [`results_chess_compare.json`](results_chess_compare.json) (`verified_paired_run`). It shows **much shorter assistant text** with project `GEMINI.md`, while **`tokens.total` can still rise** on that turn because **prompt** tokens include extra project/skill context — read the `interpretation` field.
