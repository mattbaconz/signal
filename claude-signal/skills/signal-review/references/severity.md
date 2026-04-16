# SIGNAL Review Severity Scale

Used by `signal-review` to classify every issue found in code review.

**Assignment rule:** Severity is based on **impact when triggered**, not probability of triggering. A race condition that only fires under high load is still sev4. A SQL injection that only fires on a specific input is still sev5.

---

## Scale

### Severity 5 — Critical

**Definition:** Breaks in production, security vulnerability, or data loss.

The code will cause one or more of:
- Data loss or corruption
- Security breach (injection, auth bypass, secret exposure, privilege escalation)
- Production outage (unhandled exception in hot path, deadlock)
- Regulatory violation (unencrypted PII, missing audit log)

**Fix before merge. No exceptions.**

**Examples:**
```
api.js:103|missing await on async DB write|5|add await — writes silently fail
auth.js:12|JWT secret hardcoded|5|move to env var
db/query.js:44|SQL built with string concat|5|use parameterized query
sessions.js:71|session fixation — token not rotated on login|5|regenerate token on auth
```

---

### Severity 4 — High

**Definition:** Likely runtime error. Will crash or produce wrong output under normal use.

The code is incorrect and will fail for a predictable class of inputs or conditions:
- Null/undefined dereference without guard
- Missing `await` on async call where result is used
- Off-by-one in loop bounds
- Unhandled promise rejection in request handler
- Type mismatch that causes silent coercion with wrong result

**Fix before merge.**

**Examples:**
```
utils.js:23|arr.map() called on potentially null arr|4|add null check before map
api/users.js:88|async fn called without await, result always undefined|4|add await
parser.js:14|loop upper bound uses length not length-1|4|change to < arr.length
```

---

### Severity 3 — Medium

**Definition:** Wrong behavior under specific conditions. Logic error that doesn't always manifest.

The code works most of the time but fails in an edge case or specific environment:
- Race condition requiring concurrent access
- Incorrect handling of empty/boundary input
- Logic branch that never fires (unreachable code masking a bug)
- Locale/timezone sensitivity producing wrong output in some regions
- Caching bug that produces stale data under specific conditions

**Fix before merge if the condition is reasonably triggerable in production.**

**Examples:**
```
auth.js:55|token expiry check uses local time, not UTC|3|use Date.now() consistently
search.js:30|empty query string causes unfiltered result set return|3|add early return for empty query
queue.js:67|double-processing possible if worker crashes mid-ack|3|use idempotency key
```

---

### Severity 2 — Low

**Definition:** Code smell or maintainability issue. Correct behavior, but problematic for the codebase long-term.

The code works but is:
- Dead code (unreachable branches, unused variables/imports)
- Magic numbers without named constants
- Function doing too many things (god function)
- Deep nesting making logic hard to follow
- Naming that misleads about behavior
- Missing or incorrect documentation on a public API

**Fix at author's discretion. Acceptable to defer to a cleanup PR.**

**Examples:**
```
utils/format.js:22|magic number 86400 — no named constant|2|const SECONDS_PER_DAY = 86400
auth.js:100-180|function is 80 lines handling 4 concerns|2|split into authenticate, validate, log, respond
api.js:3|unused import 'lodash'|2|remove import
```

---

### Severity 1 — Nitpick

**Definition:** Style, minor cleanup. No functional or maintainability impact.

- Formatting inconsistency
- Variable name slightly suboptimal (not misleading, just imprecise)
- Comment spelling error
- Extra blank line
- Import order

**Note:** Only include sev1 if explicitly asked, or if the project has a declared style standard that was violated. Never include sev1 findings as primary review content.

**Examples:**
```
utils.js:5|import order: third-party before local|1|move lodash import above ./helpers
components/Button.jsx:1|component file name lowercase, convention is PascalCase|1|rename to Button.jsx
```

---

## Quick Decision Guide

```
Does it lose data or create a security hole?   → sev5
Does it crash under normal use?                → sev4
Does it produce wrong output in edge cases?    → sev3
Does it make the code harder to maintain?      → sev2
Is it just a style thing?                      → sev1
```

---

## Severity in the Output Line

```
{file}:{line}|{issue}|{severity}|{fix}
```

The severity number appears in the third field. It is always a single digit 1–5. No ranges, no decimals, no modifiers like "high-4" or "4+".

```
auth.js:47|nullref on empty arr|4|add guard clause before map
api.js:103|missing await on async call|5|add await
utils.js:12|unused import lodash|1|remove import
```
