# Long-session benchmark (Gemini CLI)

## Why SIGNAL looked “more expensive” than baseline before

1. **Summing every model’s `tokens.total`** counted **router + main** (double-counting one user turn).
2. **A new `gemini` process every turn** re-paid **massive fixed overhead** (system prompt, tools). That dominated the few hundred characters of scripted “history.”
3. **Two full passes** (baseline then SIGNAL) added **run-to-run variance**; **turn 1** especially differed by tens of thousands of tokens for the **same** short user line.
4. **Quick (5 turns)** never starts a **second chunk**, so SIGNAL and baseline are the **same shape** — any token gap is mostly **noise**, not protocol savings. Use **`-Smoke` (6 turns)** or a **full 15-turn** run to see chunk boundaries.

## What the script does now

- **Baseline:** **One session** using `--resume`; after turn 1, each call only sends the **new user line** (realistic chat growth).
- **SIGNAL-3:** **Chunked sessions** every 5 turns: a **new** session whose **first** message is a **short CKPT line + user**; turns **inside** the chunk use `--resume` (no full cold start every line).
- **Metrics:**
  - **`tokens_primary_max`** — `max(stats.models.*.tokens.total)` per turn (avoids router+main double-count).
  - **`delta_pct_primary_max_excluding_turn1`** — sum of primary_max for **turns 2..n**; turn 1 is mostly **cold-start noise** when comparing modes back-to-back.
  - **Per-turn** — first-model `tokens.prompt` and estimated output when present in JSON (OAuth vs API key may omit cached fields; see [docs/token-metrics.md](../../docs/token-metrics.md)).
- **Retries** — transient failures (429, quota, etc.) retry with exponential backoff via [`../lib/gemini-invoke.ps1`](../lib/gemini-invoke.ps1).
- **Run metadata** — `results_*.json` include `run_metadata` (CLI version, `auth_mode_hint`, `git_short`, `run_id`).

### Optional: project context

- **`-FixtureDir <path>`** — use this directory as **WorkingDirectory** for every `gemini` invocation (default: this folder). Use when you want `GEMINI.md` or project files loaded from a fixture.
- **`-SeedGeminiMinTemplate`** — copy repo-root **`templates/gemini-GEMINI.min.md`** → **`GEMINI.md`** inside `-FixtureDir` before the run (**requires `-FixtureDir`**). Makes “equal footing” always-on SIGNAL defaults explicit.

### Rate limits

- **`-DelayMs <n>`** — pause after **each** turn (milliseconds) to reduce 429s on long runs. Official guidance: space requests when hitting quota ([FAQ 429](https://google-gemini.github.io/gemini-cli/docs/faq.html)).

## Run

From repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode LongSession -Quick
```

Or from this directory:

```powershell
.\run_long_session.ps1 -Quick              # 5 turns — sanity only
.\run_long_session.ps1 -Smoke              # 6 turns — at least one CKPT chunk for SIGNAL
.\run_long_session.ps1                     # full turns.json length (15 turns)
.\run_long_session.ps1 -FixtureDir . -SeedGeminiMinTemplate   # seed GEMINI.md here from template
.\run_long_session.ps1 -DelayMs 500        # pause 500ms between turns
```

- `turns.json` — scripted user messages (15 turns; chess-validator scenario).
- Outputs: `results_baseline.json`, `results_signal.json`, `results_compare.json`; full (non-`-Quick`) runs also append **`RESULTS.md`**.

## When you should see savings

- **Tokens:** Prefer **`delta_pct_primary_max_excluding_turn1`** and/or **full 15-turn** runs. After turn 5, baseline’s **resume** context keeps growing; SIGNAL **starts a new chunk** with a tiny CKPT instead of 5 full exchanges in the prompt.
- **Chars:** With **n > 5**, **`signal_message_chars_sum`** can still be **lower than** naive full-history paste because we never send turns 1–5 again after a CKPT (chunked design).

## Edit the scenario

Change `turns.json` (array of user strings).
