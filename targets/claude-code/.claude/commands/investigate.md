# Systematic Debugging

## Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Fixing symptoms creates whack-a-mole debugging. Every fix that doesn't address root cause makes the next bug harder to find. Find the root cause, then fix it.

---

## Phase 1: Root Cause Investigation

Gather context before forming any hypothesis.

1. **Collect symptoms:** Read error messages, stack traces, reproduction steps. If context is missing, ask ONE question at a time.

2. **Read the code:** Trace the code path from symptom back to potential causes. Use Grep to find references, Read to understand logic.

3. **Check recent changes:**
   ```bash
   git log --oneline -20 -- <affected-files>
   ```
   Was this working before? What changed? A regression means the root cause is in the diff.

4. **Reproduce:** Can you trigger the bug deterministically? If not, gather more evidence.

Output: **"Root cause hypothesis: ..."** — a specific, testable claim.

---

## Phase 2: Pattern Analysis

Check if this matches a known pattern:

| Pattern | Signature | Where to look |
|---------|-----------|---------------|
| Race condition | Intermittent, timing-dependent | Concurrent access to shared state |
| Nil/null propagation | NoMethodError, TypeError | Missing guards on optional values |
| State corruption | Inconsistent data, partial updates | Transactions, callbacks, hooks |
| Integration failure | Timeout, unexpected response | External API calls, service boundaries |
| Configuration drift | Works locally, fails in staging/prod | Env vars, feature flags, DB state |
| Stale cache | Shows old data, fixes on cache clear | Redis, CDN, browser cache |

Also check:
- `TODOS.md` for related known issues
- `git log` for prior fixes in the same area — **recurring bugs in the same files are an architectural smell**

---

## Phase 3: Hypothesis Testing

Before writing ANY fix, verify your hypothesis.

1. **Confirm:** Add a temporary log/assertion at the suspected root cause. Run reproduction. Does evidence match?

2. **If wrong:** Return to Phase 1. Gather more evidence. Do not guess.

3. **3-strike rule:** If 3 hypotheses fail, **STOP.** Ask:
   ```
   3 hypotheses tested, none match. This may be architectural.

   A) Continue — I have a new hypothesis: [describe]
   B) Escalate — needs someone who knows the system
   C) Add logging and wait — instrument the area, catch it next time
   ```

**Red flags — slow down if you see:**
- "Quick fix for now" — there is no "for now." Fix it right or escalate.
- Proposing a fix before tracing data flow — you're guessing.
- Each fix reveals a new problem — wrong layer, not wrong code.

---

## Phase 4: Implementation

Once root cause is confirmed:

1. **Fix the root cause, not the symptom.** Smallest change that eliminates the actual problem.

2. **Minimal diff:** Fewest files, fewest lines. Resist refactoring adjacent code.

3. **Write a regression test** that:
   - **Fails** without the fix (proves the test is meaningful)
   - **Passes** with the fix (proves the fix works)

4. **Run the full test suite.** Paste the output. No regressions allowed.

5. **If fix touches >5 files:** Flag the blast radius:
   ```
   This fix touches N files. Large blast radius for a bug fix.
   A) Proceed — root cause genuinely spans these files
   B) Split — fix critical path now, defer the rest
   C) Rethink — maybe there's a more targeted approach
   ```

---

## Phase 5: Verification & Report

**Fresh verification:** Reproduce the original bug scenario and confirm it's fixed. Not optional.

Run the test suite and paste output.

```
DEBUG REPORT
════════════════════════════════════════
Symptom:         [what the user observed]
Root cause:      [what was actually wrong]
Fix:             [what was changed, with file:line references]
Evidence:        [test output, reproduction showing fix works]
Regression test: [file:line of the new test]
Related:         [TODOS.md items, prior bugs in same area]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

## Rules
- 3+ failed fix attempts → STOP and question the architecture.
- Never apply a fix you cannot verify.
- Never say "this should fix it." Verify and prove it.
- If fix touches >5 files → ask about blast radius.

## Next Step

Standalone command. After investigating, run `/review` and `/ship` if you made code changes, or start fresh with `/plan` if the investigation revealed a bigger problem.
