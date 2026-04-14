---
mode: "agent"
description: "Test, review, commit, push, and create PR"
---
# Ship — Test, Review, and Open PR

Fully automated ship workflow. Run straight through and output the PR URL at the end.

**Only stop for:** merge conflicts, test failures in your branch, review findings needing judgment, missing test framework (offer to bootstrap).

**Never stop for:** uncommitted changes (always include), commit message approval, auto-fixable review findings.

## Step 1: Pre-flight

```bash
BRANCH=$(git branch --show-current)
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)
[ -z "$BASE" ] && BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE="main"
echo "Shipping: $BRANCH → $BASE"
```

If on the base branch: "You're on the base branch. Ship from a feature branch." **STOP.**

```bash
git status
git diff "$BASE"...HEAD --stat
git log "$BASE"..HEAD --oneline
```

## Step 2: Merge Base Branch

Fetch and merge so tests run against the merged state:

```bash
git fetch origin "$BASE" && git merge "origin/$BASE" --no-edit
```

If merge conflicts: **STOP.** Show conflicts.

## Step 3: Run Tests

Detect and run the project's test suite:

```bash
# Detect test runner
[ -f package.json ] && grep -q '"test"' package.json && echo "NPM_TEST"
[ -f Gemfile ] && echo "RUBY_TEST"
[ -f pytest.ini ] || [ -f pyproject.toml ] && echo "PYTHON_TEST"
[ -f go.mod ] && echo "GO_TEST"
[ -f Cargo.toml ] && echo "RUST_TEST"
```

Run the appropriate test command. If multiple test suites exist, run them all.

### Test Failure Triage

For each failing test:
1. Get files changed: `git diff origin/$BASE...HEAD --name-only`
2. Classify:
   - **In-branch:** test file or tested code was modified on this branch. **STOP** — fix before shipping.
   - **Pre-existing:** neither test nor code was modified. Ask user: A) Fix now B) Add TODO C) Skip

## Step 4: Test Coverage Audit

Detect test framework and count coverage:

```bash
# Count test files
find . -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' 2>/dev/null | grep -v node_modules | wc -l
```

For each file changed in the diff, check if a corresponding test file exists. Output coverage diagram:

```
COVERAGE AUDIT
═══════════════
[+] src/services/new-feature.ts — test/new-feature.test.ts EXISTS ✓
[-] src/utils/helper.ts — NO TEST FILE
[+] src/api/endpoint.ts — test/api/endpoint.test.ts EXISTS ✓

Coverage: 2/3 changed files have tests (67%)
```

If coverage gaps exist for new code: generate the missing test files. Run them. If they pass, include them.

## Step 5: Plan Completion Audit

Check whether the shipped code matches a plan file, if one exists.

### Discovery

Look for a plan or design doc related to this branch:

```bash
BRANCH=$(git branch --show-current 2>/dev/null | tr '/' '-')
# Search common plan file locations
for PLAN_DIR in ".claude/plans" ".github/plans" "docs/plans" "."; do
  [ -d "$PLAN_DIR" ] || continue
  PLAN=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | xargs grep -l "$BRANCH" 2>/dev/null | head -1)
  [ -n "$PLAN" ] && break
done
# Also check for design docs with branch name in title
[ -z "$PLAN" ] && PLAN=$(find . -maxdepth 2 -name "*design*" -name "*.md" -newer "$(git merge-base HEAD origin/$BASE)" 2>/dev/null | head -1)
[ -n "$PLAN" ] && echo "PLAN_FILE: $PLAN" || echo "NO_PLAN_FILE"
```

**No plan file found:** Skip with "No plan file detected — skipping." Continue to Step 6.

### Audit

If a plan file was found:

1. Read it. Extract every actionable item (checkbox items, numbered steps, imperative statements like "Add X", "Create Y", file specifications). Exclude: section headers, commentary, questions, explicitly deferred items ("Future:", "Out of scope:", "P2+").
2. For each item, check the diff: does the code address it?
3. Classify each as: **DONE** (addressed in diff), **PARTIAL** (started but incomplete), **NOT DONE** (no matching changes).

```
PLAN COMPLETION AUDIT
═══════════════════════════════
Plan: {plan file path}

  [DONE]      Create UserService — src/services/user_service.rb (+142 lines)
  [PARTIAL]   Add validation — model validates but missing controller checks
  [NOT DONE]  Add caching layer — no cache-related changes in diff

Completion: 4/6 items (67%)
```

### Gate

- **All DONE:** Pass. Continue.
- **Only PARTIAL items (no NOT DONE):** Continue with a note in the PR body.
- **Any NOT DONE items:** Ask:
  ```
  {N} items from the plan are NOT DONE:
  - {list}

  A) Stop — implement the missing items before shipping
  B) Ship anyway — defer these to a follow-up
  C) These items were intentionally dropped
  ```

Include a `## Plan Completion` section in the PR body (Step 8).

## Step 6: Pre-Landing Review

Run the core review checklist against the diff (same as `/sl-review` but abbreviated):

**Critical pass:** SQL safety, race conditions, LLM trust boundaries, shell injection, enum completeness.

**Fix-first:** AUTO-FIX mechanical issues. ASK about ambiguous ones.

Output: `Pre-Landing Review: N issues (X auto-fixed, Y need input)`

## Step 7: Commit

Split changes into bisectable commits where logical. Each commit = one logical change.

```bash
git add -A
git commit -m "<type>: <summary>"
```

Use conventional commit prefixes: feat, fix, refactor, test, chore, docs.

## Step 8: Push

```bash
git fetch origin "$BRANCH" 2>/dev/null
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "none")
[ "$LOCAL" = "$REMOTE" ] && echo "Already pushed" || git push -u origin "$BRANCH"
```

## Step 9: Create PR

Check if PR exists:
```bash
gh pr view --json url,state -q '.url' 2>/dev/null || echo "NO_PR"
```

If PR exists: update body with latest results. If no PR: create one.

PR body:
```
## Summary
<Summarize all changes. Group into logical sections.>

## Plan Completion
<If plan file found: completion checklist from Step 5. If none: "No plan file detected.">

## Test Coverage
<coverage diagram from Step 4>

## Pre-Landing Review
<findings from Step 6>

## Test Plan
- [x] All tests pass (N tests, 0 failures)

Generated with stacklite /sl-ship
```

```bash
gh pr create --base "$BASE" --title "<type>: <summary>" --body "<body>"
```

If `gh` unavailable: print branch name, remote URL, instruct user to create PR manually.

**Output the PR URL.**

## Step 10: Update Docs

After PR creation, scan all .md files in the project. Cross-reference against the diff. Auto-update factual changes (paths, counts, feature lists). Ask about narrative changes.

If any docs updated:
```bash
git add -A && git commit -m "docs: sync with shipped changes" && git push
```

## Rules
- Never skip tests. If tests fail, stop.
- Never force push.
- Never ask for trivial confirmations.
- The goal: user says `/sl-ship`, next thing they see is the PR URL.

## Next Step

Run `/sl-doc` to update documentation after shipping. Then `/sl-retro` at the end of the week to reflect on what was shipped.
