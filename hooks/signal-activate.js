#!/usr/bin/env node
/**
 * Claude Code SessionStart hook — SIGNAL workspace defaults.
 * Installed to ~/.claude/hooks/signal-activate.js by hooks/install.ps1 / install.sh
 */
const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.signal-active');

try {
  fs.writeFileSync(flagPath, 'on\n', 'utf8');
} catch (e) {
  /* non-fatal */
}

const core =
  'SIGNAL ACTIVE — follow the **signal** skill. Tiers: /signal, /signal2, /signal3. ' +
  'Default SIGNAL-1: terse, no preamble, no hedging; fragments OK; non-obvious claims → [0.0–1.0]. ' +
  'Never compress code blocks, file paths, line numbers, quoted errors, or technical terms. ' +
  'Workflow skills: signal-commit, signal-push, signal-pr, signal-review, signal-ckpt. ' +
  'Escape: SIGNAL_DRIFT: <reason>. Full protocol: bundle README and signal/SKILL.md.';

process.stdout.write(core);
process.exit(0);
