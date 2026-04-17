# Changelog

All notable changes to this project are documented here. The format is informal; this repo tracks the SIGNAL skill suite as one deliverable.

**Versioning:** For each release, align `**signal_bundle_version`** in core `SKILL.md` frontmatter, a new section below, and an annotated git tag (`v0.x.y`). Optional: GitHub Release from that tag (see README *Releases and community*).

## v0.2.1 — 2026-04-18

Git tag: `**v0.2.1`** (recommended after merge).

### Added

- `**[signal/references/karpathy-coding-norms.md](signal/references/karpathy-coding-norms.md)**` — Karpathy-inspired coding discipline for implementation/editing (think before coding, simplicity first, surgical changes, goal-driven execution), adapted from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT) with attribution; mapped to SIGNAL templates and `SIGNAL_DRIFT`. Wired into `[signal/SKILL.md](signal/SKILL.md)`, `[templates/host-always-on.body.md](templates/host-always-on.body.md)`, `[templates/gemini-GEMINI.md](templates/gemini-GEMINI.md)` / `[claude-CLAUDE.md](templates/claude-CLAUDE.md)` (+ `.min`), and `[gemini-signal/GEMINI.md](gemini-signal/GEMINI.md)`.

### Changed

- `signal_bundle_version` in core `SKILL.md` frontmatter set to **0.2.1** (aligned with extension/plugin manifests).
- **Gemini extension at repository root** (from prior unreleased work): `[scripts/sync-integration-packages.ps1](scripts/sync-integration-packages.ps1)` mirrors `gemini-signal/` to the repo root for **[geminicli.com/extensions](https://geminicli.com/extensions/browse/)** and `gemini extensions install https://github.com/mattbaconz/signal` ([releasing](https://geminicli.com/docs/extensions/releasing)); add topic `**gemini-cli-extension`** on this repo.

## v0.2.0 — 2026-04-17

Git tag: `**v0.2.0**`.

### Added

- **Host IDE rules (single source):** `[templates/host-always-on.body.md](templates/host-always-on.body.md)` + `[scripts/sync-host-integrations.ps1](scripts/sync-host-integrations.ps1)` generate `[.cursor/rules/signal.mdc](.cursor/rules/signal.mdc)`, `[.windsurf/rules/signal.md](.windsurf/rules/signal.md)`, `[.clinerules/signal.md](.clinerules/signal.md)`, `[.github/copilot-instructions.md](.github/copilot-instructions.md)`. Run automatically from `[scripts/verify.ps1](scripts/verify.ps1)`.
- **OpenAI Codex:** `[.codex/config.toml](.codex/config.toml)` + `[.codex/hooks.json](.codex/hooks.json)` — SessionStart runs `[hooks/signal-session-reminder.js](hooks/signal-session-reminder.js)` (stdout reminder; Windows Codex may disable hooks — see README).
- **Claude Code hooks (optional):** `[hooks/install.ps1](hooks/install.ps1)` / `[hooks/install.sh](hooks/install.sh)`, `[hooks/uninstall.ps1](hooks/uninstall.ps1)` / `[hooks/uninstall.sh](hooks/uninstall.sh)`, `[hooks/signal-activate.js](hooks/signal-activate.js)`, `[hooks/signal-statusline.ps1](hooks/signal-statusline.ps1)` / `[hooks/signal-statusline.sh](hooks/signal-statusline.sh)`, `[hooks/README.md](hooks/README.md)`.

### Changed

- `signal_bundle_version` in core `SKILL.md` frontmatter set to **0.2.0** (aligned with extension/plugin manifests).
- **README:** badges (license, release, CI, Discord), slogan (*Less noise, same signal.*), mermaid diagrams (token buckets + tiers), benchmark snapshot, Star History chart, repository layout for hooks/IDE paths; cross-tool section documents repo-local rules.
- **Chess benchmark:** `EqualContext` arms use **matched** `GEMINI.md` layout; `run_chess_compare.ps1` reports on-disk sizes and JSON parity fields; README Evidence tables archived results.
- `[docs/token-metrics.md](docs/token-metrics.md)`: input checklist, benchmark pointer, repo-local rules + hooks pointer.

## v0.1.2 — 2026-04-16

Git tag: `**v0.1.2`**.

### Added

- `[docs/signal-compress.md](docs/signal-compress.md)` — input-side compression workflow (shrink `GEMINI.md` / notes; backup, rewrite, diff review).
- `[templates/signal-compress-prompt.md](templates/signal-compress-prompt.md)` — copy-paste SIGNAL-1 compression prompt for memory files.
- `[scripts/signal-compress.ps1](scripts/signal-compress.ps1)` — backup helper (`-Path`, `-DryRun`, optional `-InvokeGemini` that only prints the command).

### Changed

- `signal_bundle_version` in core `SKILL.md` frontmatter set to **0.1.2** (aligned with extension/plugin manifests).
- README: new **SIGNAL vs Caveman (token compression)** subsection under *Maximize token savings*; repository layout and *Further reading* list the new docs/script.
- `[docs/token-metrics.md](docs/token-metrics.md)`: new *Reducing input tokens* subsection linking the thin templates and `signal-compress.md`.
- `[benchmark/benchmark chess/run_chess_compare.ps1](benchmark/benchmark%20chess/run_chess_compare.ps1)`: JSON now surfaces `baseline_prompt_tokens` / `signal_prompt_tokens` / `delta_prompt_tokens` / `delta_pct_prompt_vs_baseline`; adds a three-line stdout summary (prompt / total / response_chars).
- `[benchmark/benchmark chess/README.md](benchmark/benchmark%20chess/README.md)`: clarified that `tokens.total` mixes prompt and generation and documented `response_chars` as the fallback output signal.

## v0.1.1 — 2026-04-16

Git tag: `**v0.1.1`**.

### Added

- `**[scripts/benchmark.ps1](scripts/benchmark.ps1)**` — reproducible token-estimate scenarios (4 chars/token heuristic).
- `**[gemini-signal/](gemini-signal/)**` — Gemini CLI extension (`gemini-extension.json`, bundled `GEMINI.md`, synced `skills/`, `commands/signal/*.toml`, `bin/run-commit.*` / `run-push.*`).
- `**[claude-signal/](claude-signal/)**` — Claude Code plugin (`.claude-plugin/plugin.json`, synced `skills/`).
- `**[.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)**` — marketplace catalog for `/plugin install signal@signal-suite`.
- `**[scripts/sync-integration-packages.ps1](scripts/sync-integration-packages.ps1)**` — copies the six core skill folders into `gemini-signal/skills/` and `claude-signal/skills/` (also run automatically at the start of `[scripts/verify.ps1](scripts/verify.ps1)`).

### Changed

- `signal_bundle_version` in core `SKILL.md` frontmatter set to **0.1.1** (aligned with extension/plugin manifests).

### Documentation

- `[contrib/README.md](contrib/README.md)` + `[contrib/awesome-agent-skills-add-signal.patch](contrib/awesome-agent-skills-add-signal.patch)` — optional PR to [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills); README notes [skills.sh](https://skills.sh) discovery.
- README: [Discord](https://discord.gg/4Dkt9CaK8M) community server link in the header.

### Fixed

- README platform matrix: corrected broken markdown link for the Gemini GEMINI.md cascade doc.

## v0.1.0 — 2026-04-15

### Added

- Core skill `[signal/](signal/)` — SIGNAL-1/2/3 tiers, six compression layers, references (`symbols`, `boot-presets`, `checkpoint`).
- Workflow skills: `[signal-commit](signal-commit/)`, `[signal-push](signal-push/)`, `[signal-pr](signal-pr/)`, `[signal-review](signal-review/)`, `[signal-ckpt](signal-ckpt/)`.
- Bash automation: `commit.sh`, `push.sh`, `pr.sh`.
- Windows-native PowerShell: `commit.ps1`, `push.ps1`, `pr.ps1` (no Git Bash required for local script runs).
- README — host-aware tier defaults, cross-tool porting matrix, releasing checklist, and community evidence (single canonical doc; optional private overlays listed in `.gitignore`).
- Benchmark methodology summarized in README; optional local `benchmark/` directory is gitignored (not published).
- `[templates/gemini-GEMINI.md](templates/gemini-GEMINI.md)` and `[templates/claude-CLAUDE.md](templates/claude-CLAUDE.md)` for merging into project agent docs.
- `[scripts/install-signal-all.ps1](scripts/install-signal-all.ps1)` — copy all skills into standard user skill folders on Windows.
- `[scripts/verify.ps1](scripts/verify.ps1)` — automated checks (script `--dry` smoke tests + relative markdown link targets).

### Documentation

- README: Agent Skills compatibility, `v0.1.0`, choosing a tier, scripts on Windows, verification entry point, brand logo under `assets/`.
- Long-session harness (if maintained locally under `benchmark/`): `RESULTS.md` / JSON artifacts stay private to the clone.
- README: spec-style onboarding (skill catalog, invocation map, tier summary, TOC); clarifies normative docs vs this file.
- Repository: `.gitignore` for common OS, env, editor, and tooling artifacts; optional **untracked** root markdown overlays and `**benchmark/`** for local notes and reproducibility scripts while README stays canonical in git.
