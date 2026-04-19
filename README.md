
<p align="center">
  <img src="assets/signal-logo.png" alt="SIGNAL logo" width="130" />
</p>

<h1 align="center">SIGNAL · v0.3.1</h1>

<p align="center"><strong>Less prompt noise. More room for code.</strong><br />
Agent skills that default to dense output: minified <code>.min.md</code> payloads, symbol shorthand, optional checkpoints.</p>

<p align="center">
  <a href="https://github.com/mattbaconz/signal/stargazers"><img src="https://img.shields.io/github/stars/mattbaconz/signal?style=flat-square&logo=github&label=stars" alt="GitHub stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/mattbaconz/signal?style=flat-square" alt="License" /></a>
  <a href="https://github.com/mattbaconz/signal/actions"><img src="https://img.shields.io/github/actions/workflow/status/mattbaconz/signal/verify.yml?branch=main&style=flat-square&label=CI" alt="CI" /></a>
  <img src="https://img.shields.io/badge/release-v0.3.1-5865F2?style=flat-square" alt="Version" />
</p>

### At a glance

| Topic | Summary |
| --- | --- |
| **What you get** | Shorter **instructions + replies** in the agent; **checkpoints** (S3) instead of pasting full thread history when you want them. |
| **What you run** | `npx skills add mattbaconz/signal` → **`/signal`** (light) · **`/signal2`** (default) · **`/signal3`** (auto-CKPT). |
| **What this tree is** | **`skills/`** = source specs you edit. **`gemini-signal/`** · **`claude-signal/`** = mirrored host packages (don’t hand-edit; see [CONTRIBUTING](CONTRIBUTING.md)). |

Protocol entrypoints: [`skills/signal.min.md`](skills/signal.min.md) · symbols [`skills/signal-core.min.md`](skills/signal-core.min.md) · repo [github.com/mattbaconz/signal](https://github.com/mattbaconz/signal) · releases [CHANGELOG.md](CHANGELOG.md)

<p align="center">
  <a href="#demo">Demo</a> ·
  <a href="#install">Install</a> ·
  <a href="#commands">Commands</a> ·
  <a href="#benchmark">Benchmark</a> ·
  <a href="#repo-map">Repo map</a> ·
  <a href="#architecture">Architecture</a> ·
  <a href="#changelog">Changelog</a>
</p>

<p align="center"><a href="#before--after">Before / after</a> · <a href="#tiers">Tiers</a> · <a href="#coding-norms-karpathy-style">Karpathy norms</a> · <a href="#git-workflows--ci">Git &amp; CI</a> · <a href="#star-history">Stars</a></p>

---

## Demo

![SIGNAL benchmark — scripted scenarios, skill shrink, and live Gemini snapshot](assets/signal-benchmark-results.png)

**What you’re looking at:** three **scripted** savings shapes (A–C), **skill file** shrink (`.md` → `.min.md`), and one **live Gemini** snapshot (single-turn; prompt-heavy totals vs shorter replies — see [Benchmark](#benchmark)). Heuristic = `ceil(chars/4)`; API math = [`docs/token-metrics.md`](docs/token-metrics.md). Run: [`scripts/benchmark.ps1`](scripts/benchmark.ps1) · [`benchmark/README.md`](benchmark/README.md).

---

## Before / after

| 👤 **Verbose agent** | 🌐 **SIGNAL** |
| --- | --- |
| “I think the problem might be in `auth.js` around line 47…” | `auth.js:47` · null ref · guard — **~7× fewer tokens** in the scripted benchmark. |
| Paste 10 turns of chat + tool noise into context. | **CKPT atom**: stack, progress, next step — transcript stays out of the window. |
| One giant `SKILL.md` tree + references forever. | **Canonical `.md`** for humans, **`.min.md`** for the agent — **~87%** smaller on the seven main pairs ([Benchmark](#benchmark)). |

---

## Install

```bash
npx skills add mattbaconz/signal
```

Global:

```bash
npx skills add mattbaconz/signal -y -g
```

**After install:** open [`skills/signal.min.md`](skills/signal.min.md), pick **S1 / S2 / S3**, add workflow skills (`signal-commit`, …) only when you need them.

---

## Commands

| Command | What it does |
| --- | --- |
| `/signal` | S1 — entry tier |
| `/signal2` | S2 — strong default |
| `/signal3` | S3 — auto-CKPT |
| `/signal-commit` | Stage + conventional commit |
| `/signal-push` | Commit + push |
| `/signal-pr` | Push + PR (`gh`) |
| `/signal-review` | One-line review, severity required |
| `/signal-state` | `.signal_state.md` |
| `/signal-diff` | Summarized changes |
| `/signal-search` | Summarized search |

Tier detail: [Tiers](#tiers).

---

## Repo map

There is **no** legacy top-level `signal/` directory in this repo—ignore older docs that referred to it. This table is what you actually open after cloning.

| Location | What it is | You need it if… |
| --- | --- | --- |
| [`skills/`](skills/) | **Canonical** skill specs: `*.md` (readable) + `*.min.md` (dense) | You install via `npx skills add` or copy skills into an agent |
| [`gemini-signal/`](gemini-signal/), [`claude-signal/`](claude-signal/) | **Mirrored** host extension layouts (`SKILL.md` per tool) | You ship the Gemini CLI or Claude Code plugin from this tree |
| [`references/`](references/) | Shared refs (symbols, Karpathy norms, benchmarks, checkpoint notes) | You cite norms or symbols |
| [`templates/`](templates/) | Snippets to merge into a **project’s** GEMINI / CLAUDE files | You integrate SIGNAL into an app repo |
| [`scripts/`](scripts/) | `shrink.ps1`, `sync-integration-packages.ps1`, `verify.ps1`, `benchmark.ps1` | You contribute or verify locally ([CONTRIBUTING.md](CONTRIBUTING.md)) |

---

## Why SIGNAL

Same idea as [At a glance](#at-a-glance), with moving parts: **symbols** instead of paragraphs, **`.signal_state.md`** for durable state, **signal-diff** / **signal-search** instead of raw dumps — all optional tools you pull in when the session needs them.

```mermaid
flowchart LR
  subgraph inputs [Verbose]
    V1[Long replies]
    V2[Full thread history]
    V3[Hedging and filler]
  end
  subgraph signal [SIGNAL]
    S[Symbol grammar]
    C[CKPT summaries]
    M[Minified skills]
  end
  subgraph outputs [Dense]
    D1[Terse pointers]
    D2[Checkpoint atom]
    D3[~87% smaller payloads]
  end
  V1 --> S
  V2 --> C
  V3 --> S
  S --> D1
  C --> D2
  M --> D3
```

**Cumulative** transcript savings (baseline vs checkpoint-style history) are covered in [`benchmark/README.md`](benchmark/README.md) (`benchmark/long-session/` after a full clone). **Prompt vs output vs `tokens.total`** — hosts report different scopes; see [`docs/token-metrics.md`](docs/token-metrics.md).

---

## Tiers

Use `/signal`, `/signal2`, or `/signal3`.

| Tier | You get | Rough habit savings |
| --- | --- | --- |
| **S1** | Symbols, no preamble, no hedge, terse | ~35% |
| **S2** | S1 + BOOT, aliases, delta-friendly turns | another ~20% on top |
| **S3** | S2 + **auto-checkpoint every 5 turns** | long sessions stay bounded |

---

## Symbol grammar (snippet)

| Symbol | Meaning | Example |
| --- | --- | --- |
| `→` | causes / produces | `nullref→crash` |
| `∅` | none / remove / empty | `cache=∅` |
| `Δ` | change / diff | `Δ+cache→~5ms` |
| `!` | required / must | `!fix before deploy` |
| `[n]` | confidence 0.0–1.0 | `fix logic [0.95]` |

Full reference: [`skills/signal-core.min.md`](skills/signal-core.min.md).

---

## Benchmark

Same chart as [Demo](#demo); numbers below are the tables behind it.

Heuristic: **`ceil(characters / 4)`** — not billed API tokens; good for comparing shapes.

### Reading the numbers

[`docs/token-metrics.md`](docs/token-metrics.md) explains why **`tokens.total`** can rise when you add project instructions while replies get shorter (compare **prompt** and **output** separately). For **multi-turn / cumulative** proof, run **`benchmark/long-session/`** ([`benchmark/README.md`](benchmark/README.md)) in a full clone—the tables below are reproducible snapshots from [`scripts/benchmark.ps1`](scripts/benchmark.ps1), not a substitute for long-session measurement.

### Scenarios (scripted)

| Scenario | Verbose | SIGNAL | Saved |
| --- | ---: | ---: | --- |
| A: 10-turn history vs CKPT | ~167 | ~45 | ~73% · ~3.7× |
| B: Bug paragraph vs one line | ~51 | ~7 | ~86% · ~7.3× |
| C: Hedging vs `[conf]` | ~8 | ~2 | ~75% · ~4× |

### Skill pairs (canonical `.md` → `.min.md`)

| Pair | Bytes (≈) | Est. tok (≈) | Shrink |
| --- | --- | --- | --- |
| signal | 2.8K → 0.7K | ~712 → ~182 | ~75% |
| signal-ckpt | 5.6K → 0.7K | ~1389 → ~163 | ~88% |
| signal-commit | 8.3K → 0.7K | ~2071 → ~178 | ~91% |
| signal-pr | 4.7K → 0.5K | ~1177 → ~130 | ~89% |
| signal-push | 3.7K → 0.5K | ~936 → ~131 | ~86% |
| signal-review | 5.5K → 0.6K | ~1378 → ~145 | ~90% |
| signal-state | 2.0K → 0.7K | ~511 → ~163 | ~68% |
| **7 pairs total** | **~32.7K → ~4.4K** | **~8173 → ~1090** | **~87%** |

Min-only helpers (`signal-core`, `signal-diff`, `signal-search`) ≈ **1.6K** bytes (~**389** est. tokens).

### Live Gemini (representative single-turn)

From [`benchmark/benchmark chess/run_chess_compare.ps1`](benchmark/benchmark%20chess/run_chess_compare.ps1) **`-Pair EqualContext`** (matched `GEMINI.md` ~289 vs ~296 chars). Model **`gemini-3.1-pro-preview`**. *Totals mix prompt + generation — when prompt is large, `tokens.total` moves a little even if the reply shrinks a lot.*

| Metric | Baseline | SIGNAL-style | Notes |
| --- | ---: | ---: | --- |
| `tokens.total` (max per model) | ~9,039 | ~8,333 | ~**7.8%** lower |
| `prompt_tokens` | ~8,060 | ~8,061 | Matched context (fair pair) |
| Reply (chars) | ~1,823 | ~604 | ~**67%** fewer chars |

### Reproduce

**Live** (Gemini CLI on `PATH`, auth required — refreshes JSON under `benchmark/benchmark chess/`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmark\run.ps1 -Mode Chess -Pair EqualContext
```

**Static** (heuristic scenarios; no API):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmark.ps1
```

---

## Architecture

```mermaid
flowchart TB
  subgraph protocol [Protocol layer]
    P["signal.min.md"]
    CORE["signal-core.min.md"]
  end
  subgraph workflow [Workflow skills]
    CKPT["signal-ckpt"]
    GIT["commit / push / pr"]
    REV["signal-review"]
  end
  subgraph context [Context tools]
    DIFF["signal-diff"]
    SRCH["signal-search"]
    ST["signal-state"]
  end
  subgraph persist [Persistence]
    STATE[".signal_state.md"]
  end
  P --> CORE
  P --> CKPT
  P --> GIT
  P --> REV
  P --> DIFF
  P --> SRCH
  ST --> STATE
```

**Tier ladder:**

```mermaid
flowchart LR
  S1["/signal — S1"] --> S2["/signal2 — S2"]
  S2 --> S3["/signal3 — S3"]
  S1 -.- D1["~35% vs loose chat"]
  S2 -.- D2["BOOT · aliases · Δ"]
  S3 -.- D3["Auto-CKPT every 5 turns"]
```

---

## Coding norms (Karpathy-style)

**Tiers** shape **assistant chat** (symbols, templates, checkpoints). **Karpathy-style norms** shape **implementation work** (how you edit code and ship commits): orthogonal axes—activating `/signal3` does not replace surgical diffs or explicit assumptions.

Norms in brief (canonical list: [`references/karpathy-coding-norms.md`](references/karpathy-coding-norms.md)):

1. **Assumptions** — explicit over implicit; say when unsure.
2. **Simplicity** — avoid over-engineering.
3. **Surgical diffs** — minimal changes tied to the goal.
4. **Verifiable goals** — reproduce, test, or verify where it matters.
5. **No filler** — skip “here is the code”; show the code.

| Resource | Link |
| --- | --- |
| Full norms | [`references/karpathy-coding-norms.md`](references/karpathy-coding-norms.md) |
| In skills | [`skills/signal.md`](skills/signal.md), [`skills/signal-core.min.md`](skills/signal-core.min.md) (`KarpathyNorms`), [`skills/signal-commit.min.md`](skills/signal-commit.min.md) (`followKarpathy`) |
| Host templates | [`templates/gemini-GEMINI.md`](templates/gemini-GEMINI.md), [`templates/claude-CLAUDE.md`](templates/claude-CLAUDE.md) |

---

## Git workflows & CI

| Skill | Role |
| --- | --- |
| [`skills/signal-commit.min.md`](skills/signal-commit.min.md) | Stage all, conventional commit (`--draft` / `--split`) |
| [`skills/signal-push.min.md`](skills/signal-push.min.md) | Commit + push |
| [`skills/signal-pr.min.md`](skills/signal-pr.min.md) | Commit + push + `gh pr create` |

**CI:** [`.github/workflows/verify.yml`](.github/workflows/verify.yml) runs [`scripts/verify.ps1`](scripts/verify.ps1) on Windows for `main` and PRs.

---

## Changelog

All releases: [CHANGELOG.md](CHANGELOG.md).

---

## Repository layout (clone root)

```
./
├── skills/              # canonical *.md + *.min.md (edit here; see CONTRIBUTING.md)
├── assets/              # logos, benchmark infographic
├── references/          # symbols, Karpathy norms, benchmarks, checkpoint notes
├── templates/           # Gemini / Claude merge snippets
├── scripts/             # benchmark.ps1, shrink.ps1, verify.ps1, sync-integration-packages.ps1
├── gemini-signal/       # Gemini CLI extension (mirrored from skills/)
├── claude-signal/       # Claude Code plugin (mirrored from skills/)
├── hooks/
└── GEMINI.md            # root context (synced from gemini-signal/)
```

---

## Star History

<a href="https://www.star-history.com/?repos=mattbaconz%2Fsignal&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=mattbaconz/signal&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=mattbaconz/signal&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=mattbaconz/signal&type=date&legend=top-left" />
 </picture>
</a>

---

*v0.3.1 — Shrinking Session. Brutalist token compression.*
