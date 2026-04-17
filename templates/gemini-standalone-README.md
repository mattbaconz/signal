# SIGNAL — Gemini CLI extension

**Standalone repository** for the [Gemini CLI extension gallery](https://geminicli.com/extensions/browse/): `gemini-extension.json` lives at the **repository root** so `gemini extensions install <url>` and the gallery crawler work as documented.

Full project (skills source, benchmarks, Claude plugin, IDE rules): **[github.com/mattbaconz/signal](https://github.com/mattbaconz/signal)**. This repo tracks the packaged extension only; sync from that monorepo via `scripts/sync-integration-packages.ps1` + [`scripts/sync-gemini-standalone-repo.ps1`](https://github.com/mattbaconz/signal/blob/main/scripts/sync-gemini-standalone-repo.ps1).

## Install

```bash
gemini extensions install https://github.com/mattbaconz/gemini-signal --consent
```

Local dev (clone first):

```bash
gemini extensions link ./gemini-signal
# or
gemini extensions install ./gemini-signal --consent
```

Restart the CLI after install.

## Bundled pieces

- `skills/` — six SIGNAL skills (`signal`, `signal-commit`, `signal-push`, `signal-pr`, `signal-review`, `signal-ckpt`).
- `GEMINI.md` — short session defaults (merged into extension context per `contextFileName` in the manifest).
- `commands/signal/*.toml` — slash commands such as `/signal:commit` (git context + instructions).
- `bin/run-commit.*`, `bin/run-push.*` — forward to bundled scripts; run with **current directory = git repository root**.

## Protocol and tiers

See the main suite [README](https://github.com/mattbaconz/signal#readme) and [`signal/SKILL.md`](https://github.com/mattbaconz/signal/blob/main/signal/SKILL.md) in the monorepo.

## Gallery listing (maintainers)

See **[PUBLISHING.md](https://github.com/mattbaconz/gemini-signal/blob/main/PUBLISHING.md)** for the GitHub topic and release/tag notes used by the [official releasing guide](https://geminicli.com/docs/extensions/releasing).
