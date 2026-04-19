# measure_ckpt.ps1
#
# Measures what SIGNAL checkpoint compression actually replaces.
# No API calls. Uses canned representative conversation to show
# the compression ratio between verbatim history and a CKPT atom.
#
# Scope: this measures ONLY conversational history compression.
# CLI framework boot cost (system prompt + tools ~70k tokens) is NOT
# included. That overhead is outside SIGNAL's scope -- it is constant
# regardless of whether SIGNAL is active.
#
# Usage:
#   cd benchmark\ckpt-compression
#   .\measure_ckpt.ps1

$ErrorActionPreference = "Stop"

# ── Canned 5-turn conversation (chess move validator, representative output) ──

$userTurn1 = @'
We have a chess move validator in this repo. First, list what you need to know to help: files, language, test command.
'@

$modelTurn1 = @'
To help with the chess move validator I need:
1. File structure: which files contain validation logic? Likely src/move.ts or lib/chess.js.
2. Language and runtime: TypeScript, JavaScript, Python, Go?
3. Test command: npm test, pytest, go test ./... ?
4. Validation scope: all pieces or specific? Special moves (castling, en passant)?
5. Board representation: FEN strings, bitboards, array of arrays?

Please share relevant file paths or run ls src/ so I can orient quickly.
'@

$userTurn2 = @'
Assume TypeScript in src/move.ts. Describe how you would test legality of a knight move only.
'@

$modelTurn2 = @'
For knight move legality in TypeScript, verify the L-shape constraint: exactly 2 squares
in one direction and 1 square perpendicular.

Test structure:
  describe knight move legality
    test.each valid L-shapes from e4: e4->f6, e4->d6, e4->g5, e4->c5, e4->g3, e4->c3, e4->f2, e4->d2
    test.each invalid: e4->e5 (straight), e4->f5 (diagonal), e4->e4 (no move)

Implementation:
  export function isLegalKnightMove(from, to) {
    const df = abs(file(from) - file(to))
    const dr = abs(rank(from) - rank(to))
    return (df === 1 && dr === 2) || (df === 2 && dr === 1)
  }
'@

$userTurn3 = @'
Add a minimal edge case: knight jumping off board should return false. How would you name the test?
'@

$modelTurn3 = @'
Test name: 'illegal: knight destination off board returns false'

Edge cases:
  test.each off-board: a1->b-1 (rank < 1), a1->i2 (file > h), h8->j9 (both)

Guard to add to isLegalKnightMove:
  function isValidSquare(sq) {
    const file = sq.charCodeAt(0) - 97  // a=0, h=7
    const rank = parseInt(sq[1]) - 1    // 1=0, 8=7
    return file >= 0 && file <= 7 && rank >= 0 && rank <= 7
  }
  if (!isValidSquare(from) || !isValidSquare(to)) return false
'@

$userTurn4 = @'
What about a knight on a1 jumping to b3 -- legal. a1 to c2 -- also legal. Any ambiguity in SAN vs coordinates?
'@

$modelTurn4 = @'
Both are legal: a1->b3 delta=(1,2), a1->c2 delta=(2,1).

SAN vs coordinate ambiguity:
- Coordinate (from->to): fully unambiguous. Stateless check.
- SAN (Nb3): when two knights can reach b3, need disambiguation: Nab3 or N1b3.
  Requires board state, not just the move string.

Recommendation: accept coordinate pairs in src/move.ts. Let caller handle SAN.
Keeps validator pure and testable without board state. Document this boundary --
it is where most validator bugs live.
'@

$userTurn5 = @'
If the board is 8x8 with 0-based ranks/files, give the formula mapping square name e4 to indices.
'@

$modelTurn5 = @'
For 0-based indices:
  file = charCodeAt(0) - 97   // e -> 4  (a=0, b=1, ..., h=7)
  rank = parseInt(sq[1]) - 1  // 4 -> 3  (1=0, 2=1, ..., 8=7)

So e4 -> { file: 4, rank: 3 }

Inverse:
  file_char = String.fromCharCode(file + 97)
  rank_char = String(rank + 1)
  square = file_char + rank_char  // (4,3) -> "e4"

Edge: always validate 0 <= file <= 7, 0 <= rank <= 7 before converting.
'@

# ── Concatenate full verbatim history ─────────────────────────────────────────
$verbatimHistory = @"
USER: $userTurn1

MODEL: $modelTurn1

USER: $userTurn2

MODEL: $modelTurn2

USER: $userTurn3

MODEL: $modelTurn3

USER: $userTurn4

MODEL: $modelTurn4

USER: $userTurn5

MODEL: $modelTurn5
"@

$allModelResponses = @"
$modelTurn1
$modelTurn2
$modelTurn3
$modelTurn4
$modelTurn5
"@

# ── CKPT atom that replaces all 5 turns (per signal-ckpt spec) ────────────────
$ckptAtom = "CKPT[1] project=move-validator lang=ts scope=knight-validation progress=[files?,knight-legal-ok,off-board-ok,SAN-coord-boundary-ok,square-index-formula-ok] next=turn6"

# ── Size calculations ──────────────────────────────────────────────────────────
$enc = [System.Text.Encoding]::UTF8
$verbatimBytes   = $enc.GetByteCount($verbatimHistory)
$verbatimChars   = $verbatimHistory.Length
$responseBytes   = $enc.GetByteCount($allModelResponses)
$ckptBytes       = $enc.GetByteCount($ckptAtom)
$ckptChars       = $ckptAtom.Length

# Token estimate: 4 chars per token (standard rough proxy)
$verbatimTokens = [int]($verbatimChars / 4)
$responseTokens = [int]($allModelResponses.Length / 4)
$ckptTokens     = [int]($ckptChars / 4)
$ckptTokens     = [math]::Max(1, $ckptTokens)

$ratioVsVerbatim  = [math]::Round((1 - ($ckptBytes / $verbatimBytes))  * 100, 1)
$ratioVsResponses = [math]::Round((1 - ($ckptBytes / $responseBytes))  * 100, 1)
$compressionX     = [int]($verbatimTokens / $ckptTokens)

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SIGNAL CKPT Compression Ratio ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "What is being measured:" -ForegroundColor Yellow
Write-Host "  5-turn conversation: chess move validator scenario (TypeScript)."
Write-Host "  This measures what SIGNAL compresses: conversational history."
Write-Host "  CLI framework boot cost (~70k tokens) is excluded -- that is"
Write-Host "  framework overhead, constant regardless of SIGNAL."
Write-Host ""
Write-Host "--- Verbatim history (5 turns: user + model) ---" -ForegroundColor White
Write-Host ("  Chars:  " + $verbatimChars)
Write-Host ("  Bytes:  " + $verbatimBytes)
Write-Host ("  Tokens: ~" + $verbatimTokens + " (4 chars/token estimate)")
Write-Host ""
Write-Host "--- Model responses only (what grows per turn) ---" -ForegroundColor White
Write-Host ("  Bytes:  " + $responseBytes)
Write-Host ("  Tokens: ~" + $responseTokens)
Write-Host ""
Write-Host "--- CKPT atom replacing all 5 turns ---" -ForegroundColor White
Write-Host ("  " + $ckptAtom)
Write-Host ("  Chars:  " + $ckptChars)
Write-Host ("  Bytes:  " + $ckptBytes)
Write-Host ("  Tokens: ~" + $ckptTokens + " (estimated)")
Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Green
Write-Host ""
Write-Host ("  vs full 5-turn history:       " + $ratioVsVerbatim + "% smaller") -ForegroundColor Green
Write-Host ("  vs model responses only:       " + $ratioVsResponses + "% smaller") -ForegroundColor Green
Write-Host ("  compression factor:            ~" + $compressionX + "x") -ForegroundColor Green
Write-Host ""
Write-Host ("  " + $verbatimTokens + " history tokens  -->  " + $ckptTokens + " CKPT tokens") -ForegroundColor Green
Write-Host ""
Write-Host "Note on CLI sessions:" -ForegroundColor DarkGray
Write-Host "  When SIGNAL resets a session at a checkpoint, the CLI framework" -ForegroundColor DarkGray
Write-Host "  re-loads its system prompt + tools (~60-80k tokens). This boot cost" -ForegroundColor DarkGray
Write-Host "  offsets savings in short-to-medium sessions. In long sessions where" -ForegroundColor DarkGray
Write-Host "  history grows into the 10k-50k+ token range, the CKPT savings" -ForegroundColor DarkGray
Write-Host "  shown above compound and dominate." -ForegroundColor DarkGray
Write-Host ""
