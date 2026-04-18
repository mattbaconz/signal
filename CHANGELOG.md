# Changelog

All notable changes to this project are documented here. The format is informal; this repo tracks the SIGNAL skill suite as one deliverable.

**Versioning:** For each release, align `**signal_bundle_version`** in core `SKILL.md` frontmatter, a new section below, and an annotated git tag (`v0.x.y`). Optional: GitHub Release from that tag (see README *Releases and community*).

## v0.3.0 — 2026-04-18

"The Shrinking Session" — Major architecture upgrade for token density and statefulness.

### Added

- **Minified Skills:** 90%+ instruction token reduction. Canonical source: `[skills/](skills/)` (e.g., `[skills/signal-commit.min.md](skills/signal-commit.min.md)`).
- **Symbol Grammar:** Native clause replacement (`→` `⊕` `∅` `Δ` `!` `∴`). Ref: `[references/symbols.md](references/symbols.md)`.
- **State-Driven Development:** `.signal_state.md` as the persistent, atomic source of truth. Skill: `[skills/signal-state.min.md](skills/signal-state.min.md)`.
- **High-Density Tools:** `[skills/signal-diff.min.md](skills/signal-diff.min.md)` and `[skills/signal-search.min.md](skills/signal-search.min.md)` for summarized context (∅raw_code).
- **Consolidated Skills:** All skills moved to root `[skills/](skills/)`. Host extensions (`gemini-signal/`, `claude-signal/`) now mirror these files via `[scripts/sync-integration-packages.ps1](scripts/sync-integration-packages.ps1)`.
- **Testing Enforcement:** Logic changes now require: !reproduce ⊕ !test ⊕ !verify.

### Changed

- **`GEMINI.md` (root):** Upgraded to v0.3.0 standards (minified skills, symbol grammar, S1-S3 tiers).
- **`verify.ps1`:** Refactored for v0.3.0 consolidated structure and automated link checking.
- **`shrink.ps1`:** New script to automate minification of `SKILL.md` into `SKILL.min.md`.
- **`CHANGELOG.md`:** Updated all links to reflect new `skills/` and `references/` structure.

## v0.2.1 — 2026-04-18

Git tag: `**v0.2.1`**.

### Added

- **[docs/gemini-team-adoption.md](docs/gemini-team-adoption.md)** — playbook for org-wide Gemini CLI rollout.
- `**[references/karpathy-coding-norms.md](references/karpathy-coding-norms.md)**` — Karpathy-inspired coding discipline.

### Changed

- `signal_bundle_version` set to **0.3.0**.
- **Gemini extension at repository root:** `[scripts/sync-integration-packages.ps1](scripts/sync-integration-packages.ps1)` mirrors `gemini-signal/` to the repo root.

## v0.2.0 — 2026-04-17

Git tag: `**v0.2.0**`.

### Added

- **Host IDE rules (single source):** `[templates/host-always-on.body.md](templates/host-always-on.body.md)` generates rules via `[scripts/sync-host-integrations.ps1](scripts/sync-host-integrations.ps1)`.

### Changed

- README: badges, mermaid diagrams, benchmark snapshot.
- `[docs/token-metrics.md](docs/token-metrics.md)`: input checklist, benchmark pointer.

## v0.1.2 — 2026-04-16

### Added

- `[docs/signal-compress.md](docs/signal-compress.md)` — input-side compression workflow.
- `[templates/signal-compress-prompt.md](templates/signal-compress-prompt.md)` — compression prompt for memory files.

## v0.1.1 — 2026-04-16

### Added

- `**[scripts/benchmark.ps1](scripts/benchmark.ps1)**` — reproducible token-estimate scenarios.
- `**[gemini-signal/](gemini-signal/)**` — Gemini CLI extension.
- `**[claude-signal/](claude-signal/)**` — Claude Code plugin.

## v0.1.0 — 2026-04-15

### Added

- Core skills and protocol.
- Workflow skills (commit, push, pr, review, ckpt).
- Automation scripts (PowerShell + Bash).
- README and initial templates.
