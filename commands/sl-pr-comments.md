# Generate PR Review Comments

Generate review-quality comments suitable for posting on a PR. Read-only — no auto-fixes, no decision briefs, no interactive prompts. Produces markdown the user can review, edit, then post via `gh pr review --comment --body` (or pass `--post` to do that automatically).

For the interactive auto-fix flow, use `/sl-review` instead. This command is the "give it a branch, get clean PR-ready comments out" workflow.

## Usage

```
/sl-pr-comments                  → review current branch, print markdown to stdout
/sl-pr-comments <branch>         → review <branch> (no checkout), print to stdout
/sl-pr-comments --post           → review + post to PR via gh pr review
/sl-pr-comments <branch> --post  → review <branch> + post
```

## Step 1: Resolve Target Branch

Parse args. `<branch>` is a positional arg; `--post` is a flag. Either or both may be absent.

```bash
TARGET=""
POST="false"
for arg in "$@"; do
  case "$arg" in
    --post) POST="true" ;;
    *) [ -z "$TARGET" ] && TARGET="$arg" ;;
  esac
done

CURRENT=$(git branch --show-current 2>/dev/null)
[ -z "$TARGET" ] && TARGET="$CURRENT"
echo "Target branch: $TARGET"

CROSS_BRANCH="false"
[ "$TARGET" != "$CURRENT" ] && CROSS_BRANCH="true"
```

If `CROSS_BRANCH=true`, surface that in the final output so the user knows specialist passes that read files outside the diff are limited.

## Step 2: Detect Base Branch and Compute Merge-Base Diff

```bash
BASE=$(gh pr view "$TARGET" --json baseRefName -q .baseRefName 2>/dev/null)
[ -z "$BASE" ] && BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE="main"
echo "Base: $BASE"

if [ "$TARGET" = "$BASE" ]; then
  echo "Nothing to review — target is the base branch."; exit 0
fi

git fetch origin "$BASE" --quiet
DIFF_BASE=$(git merge-base "origin/$BASE" "$TARGET")
[ -z "$DIFF_BASE" ] && { echo "Could not resolve merge-base with origin/$BASE. Branch may be disjoint."; exit 1; }

git diff "$DIFF_BASE" "$TARGET" --stat
```

If `--stat` shows no changes: "No changes against $BASE." Stop.

**Why `git merge-base` and not `git diff origin/$BASE`:** the two-dot form shows all files that differ between the two branch tips, which includes PRs merged into main since the target branched. Diffing from the merge-base shows only what the target branch actually added. This is the same fix gstack landed in v1.40 for #1152.

### Large diff warning

```bash
CHANGED_LINES=$(git diff "$DIFF_BASE" "$TARGET" --shortstat | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
CHANGED_FILES=$(git diff "$DIFF_BASE" "$TARGET" --name-only | wc -l | tr -d ' ')
LARGE_DIFF="false"
if [ "$CHANGED_LINES" -gt 500 ] 2>/dev/null || [ "$CHANGED_FILES" -gt 30 ] 2>/dev/null; then
  LARGE_DIFF="true"
fi
```

If `LARGE_DIFF=true`, prepend a note to the output: "Large diff (N lines / M files). Output may be incomplete; consider scoping to specific paths."

### Read the diff

```bash
git diff "$DIFF_BASE" "$TARGET"
git log "$DIFF_BASE..$TARGET" --oneline
```

Read the FULL diff before commenting. Do not flag issues already addressed in the diff.

## Step 3: Review Passes (READ-ONLY)

Run the same passes as `/sl-review`. No auto-fixes. No decision briefs. Just collect findings.

### Pass 1 — Critical

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

If `CROSS_BRANCH=true`, mark enum-completeness findings as "(limited: cross-branch read)" — files outside the diff are read via `git show $TARGET:path` and may be less reliable than a direct checkout.

### Pass 2 — Informational

**Async/Sync Mixing:** Synchronous calls inside async functions blocking the event loop.

**Column/Field Name Safety:** ORM column names that don't match actual schema.

**LLM Prompt Issues:** 0-indexed lists (LLMs return 1-indexed), tool lists mismatching wired-up tools.

**Completeness Gaps:** Shortcuts where the complete version costs <30 min with AI.

**Time Window Safety:** Date-key lookups assuming "today" covers 24h. Mismatched time windows.

**Type Coercion at Boundaries:** Values crossing language boundaries where types could change.

**View/Frontend:** Inline style blocks in partials, O(n*m) lookups, filters that should be WHERE clauses.

**Distribution & CI/CD:** Build version mismatches, incorrect artifact paths, hardcoded secrets.

### Pass 3 — Specialist Domains

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

### Pass 4 — Adversarial

After the structured passes, do a fresh pass with a different lens. Forget the checklist — think like an attacker, a tired oncall engineer, or a user who does the unexpected.

Ask:
1. What's the worst thing that happens if this code runs in production? Trace the blast radius.
2. What breaks under concurrent access? Two users, two tabs, two deploys.
3. What happens at the boundaries? Empty input, max input, nil where you don't expect it, slow network.
4. What adjacent code breaks? The diff might be correct in isolation but break callers, consumers, or downstream systems.

## Confidence Calibration

Every finding includes a confidence score (1-10):

| Score | Meaning | Show in output |
|-------|---------|----------------|
| 9-10  | Verified by reading specific code | Yes |
| 7-8   | High confidence pattern match | Yes |
| 5-6   | Moderate, could be false positive | Yes, with caveat |
| 3-4   | Low confidence | Appendix only |

Format internally: `[SEVERITY] (confidence: N/10) file:line — description`

## Suppressions — DO NOT flag

- Redundancy that aids readability
- "Add a comment explaining why" — thresholds change, comments rot
- "This assertion could be tighter" when it already covers the behavior
- Consistency-only changes
- "Regex doesn't handle X" when input is constrained
- Anything already addressed in the diff

## Step 4: Scope Drift Detection

Check: did they build what was requested — nothing more, nothing less?

```bash
gh pr view "$TARGET" --json body --jq .body 2>/dev/null
git log "$DIFF_BASE..$TARGET" --oneline
```

Read TODOS.md if it exists. Compare files changed against stated intent.

Format:
```
Scope: [CLEAN / DRIFT DETECTED / REQUIREMENTS MISSING]
Intent: <1-line from commits/PR/TODOS>
Delivered: <1-line from diff>
[If drift: list each out-of-scope change]
[If missing: list each unaddressed requirement]
```

Informational — does not block the output.

## Step 5: Format Output

Write the markdown to a variable. Group findings by severity. Suppress confidence-3-4 findings unless severity would be P0.

```markdown
## Pre-landing review (`{TARGET}` → `{BASE}`)

{if LARGE_DIFF:
> Large diff ({CHANGED_LINES} lines / {CHANGED_FILES} files). Output may be incomplete; consider scoping to specific paths.}

{if CROSS_BRANCH:
> Note: review run from a different branch (`{CURRENT}`). Specialist passes that read files outside the diff (enum completeness, cross-file consistency) are limited.}

### Blockers ({N})

- `path/to/file.ext:42` — description (confidence: N/10)
  Recommendation: one-line fix.

### Suggestions ({N})

- `path/to/file.ext:88` — description (confidence: N/10)
  Recommendation: one-line fix.

### Adversarial findings ({N})

- description, one line.

### Scope check

- Intent: {one-line}
- Delivered: {one-line}
{if drift: - Drift: {item}}
{if missing: - Missing: {item}}

_Generated by stacklite `/sl-pr-comments`_
```

If zero findings across all passes: emit a one-line "✓ No blockers, no suggestions — looks clean." plus the scope check.

## Step 6: Output

Default: write the markdown to stdout. Do nothing else.

If `--post`:

```bash
PR_NUM=$(gh pr view "$TARGET" --json number -q .number 2>/dev/null)
if [ -z "$PR_NUM" ]; then
  echo "No open PR for branch $TARGET. Run /sl-ship first, or drop --post to print the markdown for manual paste."
  exit 1
fi

gh pr review "$PR_NUM" --comment --body "$MARKDOWN"
echo "Posted review comment on PR #$PR_NUM."
gh pr view "$PR_NUM" --json url -q .url
```

The `--comment` flag (not `--approve` / `--request-changes`) posts the body as a neutral review with no approval state.

If `gh` is not installed: print the markdown to stdout regardless and add a footer: "_Install gh to use --post. Paste this into a PR review comment manually._"

## Anti-Skip Rule

Never condense, abbreviate, or skip any pass (1–4). If a pass genuinely has zero findings, say "No issues" in your internal notes and move on — but you must evaluate it. The user is using these comments to ship code; missing a real finding is worse than running a redundant pass.

## Next Step

Run `/sl-ship` to push and open the PR — or, if the PR already exists and you just want to post the review, pass `--post`. For the interactive auto-fix flow before you ship, run `/sl-review` instead.
