# Performance Review

Analyze the current branch's diff for performance issues. Focus on problems that won't be caught by tests but will degrade user experience in production.

## Setup

```bash
BRANCH=$(git branch --show-current)
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || echo "main")
git fetch origin "$BASE" --quiet
DIFF_LINES=$(git diff "origin/$BASE" --stat | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
echo "Branch: $BRANCH  Base: $BASE  Diff: $DIFF_LINES lines"

# Detect stack
[ -f Gemfile ] && echo "STACK: Ruby"
[ -f package.json ] && echo "STACK: Node"
[ -f requirements.txt ] || [ -f pyproject.toml ] && echo "STACK: Python"
[ -f go.mod ] && echo "STACK: Go"
[ -f Cargo.toml ] && echo "STACK: Rust"
```

## Get the Diff

```bash
git diff "origin/$BASE"
```

Read the FULL diff. Only flag real problems in the changed code.

## Performance Categories

### N+1 Queries
- ORM associations traversed in loops without eager loading (.includes, joinedload, include)
- Database queries inside iteration blocks (each, map, forEach) that could be batched
- Nested serializers that trigger lazy-loaded associations
- GraphQL resolvers that query per-field instead of batching (check for DataLoader)

### Missing Database Indexes
- New WHERE clauses on columns without indexes (check migration files or schema)
- New ORDER BY on non-indexed columns
- Composite queries (WHERE a AND b) without composite indexes
- Foreign key columns added without indexes

### Algorithmic Complexity
- O(n²) or worse: nested loops over collections, Array.find inside Array.map
- Repeated linear searches that could use hash/map/set lookup
- String concatenation in loops (use join or StringBuilder)
- Sorting or filtering large collections multiple times

### Bundle Size Impact (Frontend)
- New heavy dependencies (moment.js, lodash full, jquery)
- Barrel imports instead of deep imports (import from 'library/specific')
- Large static assets committed without optimization
- Missing code splitting for route-level chunks

### Rendering Performance (Frontend)
- Fetch waterfalls: sequential API calls that could be parallel (Promise.all)
- Unnecessary re-renders from unstable references (new objects/arrays in render)
- Missing React.memo, useMemo, useCallback on expensive computations
- Layout thrashing from read-then-write DOM in loops
- Missing loading="lazy" on below-fold images

### Missing Pagination
- List endpoints returning unbounded results (no LIMIT)
- Database queries without LIMIT that grow with data volume
- API responses embedding full nested objects instead of IDs

### Blocking in Async Contexts
- Synchronous I/O inside async functions (file reads, subprocess, HTTP)
- time.sleep() / Thread.sleep() inside event-loop handlers
- CPU-intensive computation blocking main thread without worker offload

## Confidence Calibration

Every finding includes confidence (1-10):
- 9-10: Verified by reading code. Show normally.
- 7-8: High confidence pattern match. Show normally.
- 5-6: Moderate. Show with caveat.
- 3-4: Low confidence. Appendix only.

Format: `[SEVERITY] (confidence: N/10) file:line — description`

## Fix-First

AUTO-FIX: N+1 queries (add eager loading), missing lazy attributes, obvious pagination.
ASK: Algorithmic refactors, new dependencies, architectural performance changes.

## Output

```
PERFORMANCE REVIEW: N issues found
Branch: feature → main

[For each finding:]
[SEVERITY] (confidence: N/10) file:line — description
  Impact: [estimated effect on user experience]
  Fix: [specific remediation]

Summary: X findings (Y auto-fixed, Z need input)
```

## Anti-Skip Rule

Never condense, abbreviate, or skip any performance category regardless of diff size or project type. Every category exists for a reason. If a category genuinely has zero findings, say "No issues found" and move on — but you must evaluate it.

## Next Step

Run `/sl-ship` when performance issues are resolved. Or run `/sl-secure` if security hasn't been reviewed yet.
