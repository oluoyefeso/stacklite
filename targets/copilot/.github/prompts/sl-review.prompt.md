---
mode: "agent"
description: "Pre-landing diff review with auto-fix"
---
# Pre-Landing Code Review

Analyze the current branch's diff against the base branch for structural issues that tests don't catch. Fix what's obvious, ask about what's ambiguous.

## Step 1: Detect Base Branch and Check for Diff

```bash
BRANCH=$(git branch --show-current)
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)
[ -z "$BASE" ] && BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE="main"
echo "Branch: $BRANCH → Base: $BASE"
```

If on the base branch: "Nothing to review." Stop.

```bash
git fetch origin "$BASE" --quiet
git diff "origin/$BASE" --stat
```

If no diff: "No changes against $BASE." Stop.

## Step 2: Scope Drift Detection

Check: did they build what was requested — nothing more, nothing less?

1. Read commit messages: `git log origin/$BASE..HEAD --oneline`
2. Read `TODOS.md` if it exists.
3. Read PR description: `gh pr view --json body --jq .body 2>/dev/null || true`
4. Compare files changed against stated intent.

```
Scope Check: [CLEAN / DRIFT DETECTED / REQUIREMENTS MISSING]
Intent: <1-line summary>
Delivered: <1-line summary>
[If drift: list each out-of-scope change]
[If missing: list each unaddressed requirement]
```

Informational — proceed regardless.

## Step 3: Get the Diff

```bash
git fetch origin "$BASE" --quiet
git diff "origin/$BASE"
```

Read the FULL diff before commenting. Do not flag issues already addressed in the diff.

## Step 4: Critical Pass

### Pass 1 — CRITICAL

**SQL & Data Safety:**
- String interpolation in SQL — use parameterized queries
- TOCTOU races: check-then-set that should be atomic WHERE + update
- Bypassing model validations for direct DB writes
- N+1 queries: missing eager loading in loops/views

**Race Conditions & Concurrency:**
- Read-check-write without uniqueness constraint
- find-or-create without unique DB index
- Status transitions without atomic WHERE old_status UPDATE SET new_status
- Unsafe HTML rendering (html_safe, dangerouslySetInnerHTML, v-html) on user data (XSS)

**LLM Output Trust Boundary:**
- LLM-generated values written to DB without format validation
- Structured tool output accepted without type/shape checks
- LLM-generated URLs fetched without allowlist (SSRF)
- LLM output stored without sanitization (stored prompt injection)

**Shell Injection:**
- subprocess with shell=True AND string interpolation
- os.system() with variable interpolation
- eval()/exec() on LLM-generated code without sandboxing

**Enum & Value Completeness:**
When the diff introduces a new enum/status/tier/type:
- Trace through every consumer (READ, don't just grep)
- Check allowlists/filter arrays containing sibling values
- Check case/if-elsif chains for wrong defaults
Requires reading code OUTSIDE the diff.

### Pass 2 — INFORMATIONAL

**Async/Sync Mixing:** Synchronous calls inside async functions blocking the event loop.

**Column/Field Name Safety:** ORM column names that don't match actual schema.

**LLM Prompt Issues:** 0-indexed lists (LLMs return 1-indexed), tool lists mismatching wired-up tools.

**Completeness Gaps:** Shortcuts where the complete version costs <30 min with AI.

**Time Window Safety:** Date-key lookups assuming "today" covers 24h. Mismatched time windows.

**Type Coercion at Boundaries:** Values crossing language boundaries where types could change.

**View/Frontend:** Inline style blocks in partials, O(n*m) lookups, filters that should be WHERE clauses.

**Distribution & CI/CD:** Build version mismatches, incorrect artifact paths, hardcoded secrets.

### Pass 3 — SPECIALIST DOMAINS

**Testing:**
- Missing negative-path tests (error branches, guard clauses, denied permissions)
- Missing edge-case coverage (zero, negative, max-int, empty, null, unicode)
- Test isolation violations (shared mutable state, order-dependent, system clock)
- Flaky patterns (timing assertions, unordered result assertions)
- New public methods with zero test coverage

**Maintainability:**
- Dead code, unused imports, variables assigned but never read
- Magic numbers and string coupling (bare literals, hardcoded URLs)
- Stale comments and docstrings contradicting changed code
- DRY violations (3+ similar lines appearing multiple times)
- Conditional side effects (one branch updates related records, other doesn't)
- Module boundary violations (reaching into another module's internals)

**API Contracts (if API files changed):**
- Breaking changes: removed fields, changed types, new required params, changed methods/status codes
- Error response consistency across endpoints
- Missing rate limiting on new endpoints
- Pagination changes without backwards compatibility
- OpenAPI/Swagger spec not updated

**Data Migration (if migration files changed):**
- Reversibility: can this be rolled back without data loss?
- Data loss risk: dropping columns with data, truncating types, NOT NULL on existing NULLs
- Lock duration: ALTER TABLE without CONCURRENTLY on large tables
- Missing backfill strategy for new NOT NULL columns
- Multi-phase safety: migrations that break running code during rolling deploy

## Confidence Calibration

Every finding MUST include a confidence score (1-10):

| Score | Meaning | Display |
|-------|---------|---------|
| 9-10 | Verified by reading specific code | Show normally |
| 7-8  | High confidence pattern match | Show normally |
| 5-6  | Moderate, could be false positive | Show with caveat |
| 3-4  | Low confidence | Appendix only |

Format: `[SEVERITY] (confidence: N/10) file:line — description`

## Step 5: Fix-First Review

Every finding gets action.

### Classify each finding:

```
AUTO-FIX (apply without asking):        ASK (needs human judgment):
├─ Dead code / unused variables          ├─ Security (auth, XSS, injection)
├─ N+1 queries (add eager loading)       ├─ Race conditions
├─ Stale comments contradicting code     ├─ Design decisions
├─ Magic numbers → named constants       ├─ Large fixes (>20 lines)
├─ Missing LLM output validation         ├─ Enum completeness
├─ Version/path mismatches               ├─ Removing functionality
├─ Variables assigned but never read     └─ Anything changing user-visible
└─ Inline styles, O(n*m) view lookups      behavior
```

Rule of thumb: mechanical fix a senior eng wouldn't discuss = AUTO-FIX. Reasonable disagreement possible = ASK.

### Apply AUTO-FIX items directly.
`[AUTO-FIXED] [file:line] Problem → what you did`

### Batch ASK items into one question.
```
I auto-fixed N issues. M need your input:

1. [CRITICAL] file:line — Problem
   Fix: ...  → A) Fix  B) Skip

2. [INFORMATIONAL] file:line — Problem
   Fix: ...  → A) Fix  B) Skip

RECOMMENDATION: Fix both — #1 is real, #2 prevents silent corruption.
```

### Verification of Claims
- "This pattern is safe" → cite the specific line
- "This is handled elsewhere" → read and cite the handling code
- "Tests cover this" → name the test file and method
- Never say "likely handled" or "probably tested" — verify or flag as unknown

## Suppressions — DO NOT flag
- Redundancy that aids readability
- "Add a comment explaining why" — thresholds change, comments rot
- "This assertion could be tighter" when it already covers the behavior
- Consistency-only changes
- "Regex doesn't handle X" when input is constrained
- Anything already addressed in the diff

## Step 6: Adversarial Pass

After the structured review, do a fresh pass with a different lens. Forget the checklist — think like an attacker, a tired oncall engineer, or a user who does the unexpected.

Ask:
1. **What's the worst thing that happens if this code runs in production?** Trace the blast radius.
2. **What breaks under concurrent access?** Two users, two tabs, two deploys.
3. **What happens at the boundaries?** Empty input, max input, nil where you don't expect it, slow network.
4. **What adjacent code breaks?** The diff might be correct in isolation but break callers, consumers, or downstream systems. Check the integration surface.

If this pass finds issues the structured review missed, add them to the findings with `[ADVERSARIAL]` prefix.

If nothing new: "Adversarial pass: no additional findings."

## Output
```
Pre-Landing Review: N issues (X critical, Y informational)
Scope: [CLEAN / DRIFT / MISSING]

AUTO-FIXED:
- [file:line] Problem → fix applied

NEEDS INPUT:
- [file:line] Problem → recommended fix
```

Do not commit, push, or create PRs — that's `/sl-ship`.

## Anti-Skip Rule

Never condense, abbreviate, or skip any review pass (1-3) or the adversarial pass regardless of diff size or type. Every pass exists for a reason. If a pass genuinely has zero findings, say "No issues found" and move on — but you must evaluate it.

## Next Step

Run `/sl-ship` to push and create a PR. Or run `/sl-secure` and `/sl-perf` for deeper security and performance checks before shipping.
