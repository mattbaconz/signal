#!/usr/bin/env node
/**
 * Codex SessionStart hook: print a one-line reminder so the workspace loads SIGNAL context.
 * Referenced from .codex/hooks.json. No network; stdout only.
 */
const msg = [
  'SIGNAL active: follow the signal skill for tiers (/signal, /signal2, /signal3).',
  'Default SIGNAL-1: terse, no preamble; [0.0-1.0] for uncertain claims.',
  'Never compress code blocks, paths, line numbers, errors, or technical terms.',
  'Full protocol: signal/SKILL.md',
].join(' ');
console.log(msg);
process.exit(0);
