---
trigger: "model_decision"
description: "Weekly retrospective — activate when user asks for retro, weekly summary, or engineering metrics"
---

# Weekly Engineering Retrospective

Generates a comprehensive retrospective from git history, analyzing commit patterns, work sessions, code quality, and team contributions.

## Arguments
- `/retro` — last 7 days (default)
- `/retro 24h` — last 24 hours
- `/retro 14d` — last 14 days
- `/retro 30d` — last 30 days

Parse the argument for the time window. Default 7 days.

For day/week units, compute an absolute start date at local midnight:
```bash
# Example: 7 days → start from 7 days ago at midnight
START_DATE=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
echo "Window: $START_DATE to now"
```

## Step 1: Gather Raw Data

```bash
git fetch origin --quiet

# Identify who is running the retro
ME=$(git config user.name)
echo "Running retro for: $ME"

# 1. All commits with author, timestamps, stats
git log origin/main --since="$START_DATE" --format="%H|%aN|%ae|%ai|%s" --shortstat

# 2. Per-commit test vs production LOC
git log origin/main --since="$START_DATE" --format="COMMIT:%H|%aN" --numstat

# 3. Commit timestamps for session detection
git log origin/main --since="$START_DATE" --format="%at|%aN|%ai|%s" | sort -n

# 4. File hotspots (most frequently changed)
git log origin/main --since="$START_DATE" --format="" --name-only | grep -v '^$' | sort | uniq -c | sort -rn | head -20

# 5. PR numbers from commit messages
git log origin/main --since="$START_DATE" --format="%s" | grep -oE '[#!][0-9]+' | sort | uniq

# 6. Per-author commit counts
git shortlog origin/main --since="$START_DATE" -sn --no-merges

# 7. Test file count
find . -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' 2>/dev/null | grep -v node_modules | wc -l

# 8. TODOS.md backlog
cat TODOS.md 2>/dev/null || true
```

## Step 2: Compute Metrics

| Metric | Value |
|--------|-------|
| Commits to main | N |
| Contributors | N |
| PRs merged | N |
| Total insertions | N |
| Total deletions | N |
| Net LOC added | N |
| Test LOC (insertions) | N |
| Test LOC ratio | N% |
| Active days | N |

Then per-author leaderboard:
```
Contributor         Commits   +/-          Top area
You (name)               32   +2400/-300   src/services/
alice                    12   +800/-150    app/api/
bob                       3   +120/-40     tests/
```

Sort by commits descending. Current user always first, labeled "You (name)".

**Backlog Health** (if TODOS.md exists): Total open TODOs, P0/P1 count, items completed this period.

## Step 3: Commit Time Distribution

Show hourly histogram in local time:
```
Hour  Commits
 00:    4      ████
 07:    5      █████
 08:   12      ████████████
 ...
```

Identify: peak hours, dead zones, bimodal patterns, late-night clusters.

## Step 4: Work Session Detection

Detect sessions using 45-minute gap between consecutive commits. For each:
- Start/end time, commits, duration

Classify:
- **Deep sessions** (50+ min)
- **Medium sessions** (20-50 min)
- **Micro sessions** (<20 min)

Calculate: total active coding time, average session length, LOC per hour.

## Step 5: Commit Type Breakdown

Categorize by conventional commit prefix:
```
feat:     20  (40%)  ████████████████████
fix:      27  (54%)  ███████████████████████████
refactor:  2  ( 4%)  ██
```

Flag if fix ratio >50% — signals "ship fast, fix fast" pattern that may indicate review gaps.

## Step 6: Hotspot Analysis

Top 10 most-changed files. Flag:
- Files changed >5 times (churn hotspot — may need refactoring)
- Test files with high churn (flaky tests?)
- Config files changing frequently (environment instability?)

## Step 7: Per-Author Deep Dive

For each contributor (current user first):

**Strengths this period:**
- What they shipped (concrete features/fixes)
- Test coverage behavior (are they writing tests?)
- Session patterns (deep focused work vs scattered?)

**Growth opportunities:**
- Areas where test coverage could improve
- Files with high fix-to-feat ratio (quality signal)
- Patterns that could be more efficient

Keep this constructive and specific. Name the file, the pattern, the number.

## Step 8: Shipping Velocity

```
SHIPPING VELOCITY
═════════════════
LOC/day (net):     N
Commits/day:       N
Active hours/day:  N
Efficiency:        N LOC/active-hour
Test ratio:        N% of new code is tests
```

Compare to rough benchmarks:
- Solo dev with AI: 2,000-10,000 LOC/day is achievable
- Traditional team: 100-500 LOC/day per person
- Test ratio healthy: 25-40%

## Step 9: Recommendations

Based on all data, provide 3-5 specific, actionable recommendations:

1. **[Category]:** Specific observation → specific action.
   Example: "Hotspot: `auth.ts` changed 8 times this week. Consider extracting the session logic into a separate module to reduce churn."

2. **[Category]:** ...

End with:
```
RETRO SUMMARY
═════════════
Period: {start} → {end}
Shipped: {N commits, M PRs, K net LOC}
Health: {test ratio}% test coverage on new code
Top win: {biggest accomplishment}
Top risk: {biggest concern}
Next week: {1-sentence focus recommendation}
```
