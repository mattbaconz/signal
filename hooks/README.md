# Claude Code hooks (SIGNAL)

Optional **SessionStart** hook and **`[SIGNAL]` statusline** badge. Codex uses a separate script: [`signal-session-reminder.js`](signal-session-reminder.js) via [`.codex/hooks.json`](../.codex/hooks.json).

## Install

From a clone of this repository:

**Windows (PowerShell)**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\hooks\install.ps1
```

**macOS / Linux**

```bash
chmod +x hooks/install.sh hooks/signal-statusline.sh
./hooks/install.sh
```

Requires **Node.js** (merges `~/.claude/settings.json` safely).

## What it does

- Copies `signal-activate.js`, `signal-statusline.*`, and `package.json` into **`~/.claude/hooks/`** (or `%CLAUDE_CONFIG_DIR%\hooks`).
- Registers a **SessionStart** hook that emits SIGNAL defaults (tiers, `SIGNAL-1`, never-compress list, `SIGNAL_DRIFT`).
- Writes **`~/.claude/.signal-active`** so the statusline script can show **`[SIGNAL]`**.
- If you have **no** `statusLine` in `settings.json`, the installer adds one. If you already use a custom statusline, it is **not** overwritten — merge manually using the paths printed by the installer.

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\hooks\uninstall.ps1
```

```bash
./hooks/uninstall.sh
```

Removes hook entries from `settings.json` and the `.signal-active` flag. Deletes **`settings.json.bak`** are not removed; remove hook files from `~/.claude/hooks/` yourself if desired.

## Safety

- Back up: the installer copies `settings.json` to **`settings.json.bak`** before editing.
- **Do not** run untrusted hook installers; review `install.ps1` / `install.sh` first.
