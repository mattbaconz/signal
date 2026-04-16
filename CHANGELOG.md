# Changelog

All notable changes to this project are documented here. The format is informal; this repo tracks the SIGNAL skill suite as one deliverable.

## v0.1.1 — 2026-04-16

### Added

- **[`scripts/benchmark.ps1`](scripts/benchmark.ps1)** — reproducible token-estimate scenarios (4 chars/token heuristic).

- **[`gemini-signal/`](gemini-signal/)** — Gemini CLI extension (`gemini-extension.json`, bundled `GEMINI.md`, synced `skills/`, `commands/signal/*.toml`, `bin/run-commit.*` / `run-push.*`).
- **[`claude-signal/`](claude-signal/)** — Claude Code plugin (`.claude-plugin/plugin.json`, synced `skills/`).
- **[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)** — marketplace catalog for `/plugin install signal@signal-suite`.
- **[`scripts/sync-integration-packages.ps1`](scripts/sync-integration-packages.ps1)** — copies the six core skill folders into `gemini-signal/skills/` and `claude-signal/skills/` (also run automatically at the start of [`scripts/verify.ps1`](scripts/verify.ps1)).

### Changed

- `signal_bundle_version` in core `SKILL.md` frontmatter set to **0.1.1** (aligned with extension/plugin manifests).

### Documentation

- [`contrib/README.md`](contrib/README.md) + [`contrib/awesome-agent-skills-add-signal.patch`](contrib/awesome-agent-skills-add-signal.patch) — optional PR to [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills); README notes [skills.sh](https://skills.sh) discovery.

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
- Repository: `.gitignore` for common OS, env, editor, and tooling artifacts; optional **untracked** root markdown overlays and **`benchmark/`** for local notes and reproducibility scripts while README stays canonical in git.

