# Gemini CLI — chess single-turn comparison

**Purpose:** Run the **same** user prompt from [`prompt.txt`](prompt.txt) in two project folders (cold start each time).

## Which pair to use (fairness)

| `-Pair` | Use it when you want to show… | Prompt fairness |
|--------|-------------------------------|-----------------|
| **`EqualContext`** (recommended for “who spends fewer tokens / shorter replies”) | **Output style** difference with **both** sides loading a project `GEMINI.md` | **Best:** matched structure — shared **Preservation** block, **Style** differs only. On-disk `GEMINI.md` sizes are tracked in JSON (`baseline_gemini_md_chars`, `signal_gemini_md_chars`, `gemini_md_size_delta_pct`). |
| **`Default`** | “No project file” vs “SIGNAL project file” (teaches the **input tax** of adding rules) | **Poor for net tokens:** baseline has **no** `GEMINI.md`, so **`prompt_tokens` are not comparable** to SIGNAL. Still useful for **response length** vs an empty project. |

For honest marketing, lead with **`EqualContext`** numbers for single-turn comparisons; use **`Default`** only to illustrate *why* thicker `GEMINI.md` raises prompt tokens (see [`docs/token-metrics.md`](../../docs/token-metrics.md)).

## Shorter, better input (real projects)

Keep **prompt** small without dropping safety:

1. **Thin always-on file** — merge only [`templates/gemini-GEMINI.min.md`](../../templates/gemini-GEMINI.min.md) (or the Claude `.min` template) so routing to the skill is a few lines, not the whole protocol.
2. **Rewrite fat memory** — use [`docs/signal-compress.md`](../../docs/signal-compress.md) + [`templates/signal-compress-prompt.md`](../../templates/signal-compress-prompt.md) to compress long prose; keep code/paths/errors verbatim.
3. **One home for rules** — avoid duplicating SIGNAL in `GEMINI.md`, rules, and every user message; activate the skill when needed.
4. **Long threads** — real savings often come from **history** (`signal-3`, checkpoints); see [`../long-session/`](../long-session/) in a full clone.

## Folder pairs (`-Pair`)

| `-Pair` | Folders | Role |
|---------|---------|------|
| **`Default`** | [`chess baseline (no signal)`](chess%20baseline%20(no%20signal)/) vs [`chess signal (signal skill used)`](chess%20signal%20(signal%20skill%20used)/) | No project `GEMINI.md` vs SIGNAL-style project file — **input tax** vs **shorter replies**. |
| **`EqualContext`** | [`chess equal verbose`](chess%20equal%20verbose/) vs [`chess equal signal`](chess%20equal%20signal/) | **Matched** `GEMINI.md` layout (same **Preservation** section; **Style** only differs). Best **apples-to-apples** single-turn harness in this repo. |

**Prerequisites**

1. Install SIGNAL skills (once): `npx skills add mattbaconz/signal -y -g`
2. [Gemini CLI](https://github.com/google-gemini/gemini-cli) on `PATH` (`gemini --version`)

**Run**

```powershell
cd benchmark\benchmark chess
.\run_chess_compare.ps1 -Pair EqualContext
.\run_chess_compare.ps1
.\run_chess_compare.ps1 -Model <model-id>   # optional; default = CLI default model
```

The script invokes `node …/gemini.js -p <prompt> -o json --approval-mode plan` once per folder (separate cold starts), parses `stats` from JSON, and writes:

- **`Default`:** `results_chess_compare.json`
- **`EqualContext`:** `results_chess_equal_compare.json`

It also prints **on-disk `GEMINI.md` character counts** before the runs and stores them under `compare` in the JSON.

**429 / capacity**

If Google returns **429** (*No capacity* / *RESOURCE_EXHAUSTED*), wait and **retry later**, or pass **`-Model`** to a different model your CLI supports. The script does not auto-retry (keeps runs deterministic).

**Interpreting tokens**

- **`prompt_tokens`** (`stats.models.*.tokens.prompt`): everything the model read on that turn — system, project `GEMINI.md`, skill metadata, user message. A thicker `GEMINI.md` raises this; [`templates/gemini-GEMINI.min.md`](../../templates/gemini-GEMINI.min.md) keeps it small.
- **`tokens_primary_max`**: max of `stats.models.*.tokens.total` for that turn (avoids double-counting router vs main when multiple models appear). This **mixes prompt and generation** — do not read it as an output-only number.
- **Output / generation** is **not always** a separate field in Gemini JSON. In this harness we use **`response_chars`** (character count of `stats.response`) as the fallback output signal; SIGNAL's wins show up there even when `tokens.total` rises from prompt growth.
- **`gemini_md_size_delta_pct`**: how different the two project files are by **character length**. For **EqualContext**, keep this small so **`delta_prompt_tokens`** reflects host/skill noise, not one arm carrying a much larger file.
- **Cumulative proof** (history + checkpoints) is **`benchmark/long-session/`** in a full clone — not this single-turn harness.
- See **[`docs/token-metrics.md`](../../docs/token-metrics.md)** for the canonical breakdown.

**Verified numbers**

Archives may include `results_chess_compare.json` / `results_chess_equal_compare.json` from maintainer runs; reproduce with the script when API capacity allows.
