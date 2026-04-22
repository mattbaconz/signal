# Assets

- **signal-logo.png** — README hero.
- **signal-benchmark-results.png** — benchmark infographic. Copy should track [README Benchmark](../README.md#benchmark) (order of evidence and caveats).
- **claude-skill-signal-minimal.zip** — `signal/` folder with `SKILL.md` + `SKILL.min.md` for **Claude (app/web) “Upload skill”** (see [docs/claude-skills-install.md](../docs/claude-skills-install.md)).
- **claude-skill-signal-with-references.zip** — `kiro-signal/` slice so `../../references` links in `SKILL.md` resolve.

Regenerate the ZIPs after skill changes: `.\scripts\sync-integration-packages.ps1` then `.\scripts\pack-skill-zips-for-upload.ps1`.

See [benchmark/README.md](../benchmark/README.md) for Gemini CLI long-session and chess harnesses.
