# Assets

- **signal-logo.png** — README hero.
- **signal-benchmark-results.png** — benchmark infographic. Copy should track [README Benchmark](../README.md#benchmark) (order of evidence and caveats).
- **claude-skill-signal-flat.zip** — `SKILL.md` + `SKILL.min.md` at zip **root** (for picky uploaders).
- **claude-skill-signal-minimal.zip** — `signal/` folder (forward-slash paths, not `Compress-Archive`).
- **claude-skill-signal-with-references.zip** — `kiro-signal/skills/signal` + `references/`.

Regenerate the ZIPs after skill changes: `.\scripts\sync-integration-packages.ps1` then `.\scripts\pack-skill-zips-for-upload.ps1`.

See [benchmark/README.md](../benchmark/README.md) for Gemini CLI long-session and chess harnesses.
