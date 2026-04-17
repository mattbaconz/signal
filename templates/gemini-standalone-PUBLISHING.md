# Publishing / gallery

This repository is structured for the [Gemini CLI extension gallery](https://geminicli.com/extensions/browse/).

1. **Public GitHub repo** — `gemini-extension.json` at the **root** of this repository (not nested).
2. **Topic** — On GitHub: repo **About** → **Topics** → add **`gemini-cli-extension`**. The indexer uses this to discover extensions.
3. **Tags** — The crawler uses tags; publish **git tags** (e.g. `v0.2.0`) when you cut a release. See [Release extensions](https://geminicli.com/docs/extensions/releasing).

Updating from the SIGNAL monorepo (`mattbaconz/signal`):

```powershell
# From signal repo root, after skills are synced into gemini-signal/
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-gemini-standalone-repo.ps1
```

Then commit, tag, and push **this** repo.

## First-time push (empty GitHub repo)

Create `mattbaconz/gemini-signal` on GitHub (no README/license if you already have them locally), then:

```bash
cd /path/to/gemini-signal
git remote add origin https://github.com/mattbaconz/gemini-signal.git
git push -u origin main
git tag -a v0.2.0 -m "SIGNAL Gemini extension v0.2.0"
git push origin v0.2.0
```

Add the **`gemini-cli-extension`** topic in the GitHub UI.
