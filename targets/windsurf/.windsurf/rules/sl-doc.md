---
trigger: "model_decision"
description: "Documentation update — activate when user asks to update or sync documentation after shipping"
---

# Document Release — Post-Ship Documentation Update

Runs after code is committed. Ensures every documentation file is accurate and up to date. Mostly automated — make obvious factual updates directly, stop and ask only for risky or subjective decisions.

**Only stop for:** narrative/philosophy changes, large rewrites (>10 lines), removing sections, cross-doc contradictions that are subjective.

**Never stop for:** factual corrections from the diff, adding items to tables/lists, updating paths/counts/versions, fixing stale cross-references.

## Step 1: Pre-flight & Diff Analysis

```bash
BRANCH=$(git branch --show-current)
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || echo "main")
git fetch origin "$BASE" --quiet
git diff "$BASE"...HEAD --stat
git log "$BASE"..HEAD --oneline
git diff "$BASE"...HEAD --name-only
```

Discover all documentation files:
```bash
find . -maxdepth 3 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" | sort
```

Classify changes: new features, changed behavior, removed functionality, infrastructure.

Output: "Analyzing N files changed across M commits. Found K documentation files to review."

## Step 2: Per-File Audit

Read each doc file and cross-reference against the diff:

**README.md:**
- Does it describe all features visible in the diff?
- Are install/setup instructions consistent with changes?
- Are examples and usage descriptions still valid?

**ARCHITECTURE.md:**
- Do diagrams and component descriptions match current code?
- Are design decisions still accurate?
- Be conservative — only update things clearly contradicted by the diff.

**CONTRIBUTING.md — New contributor smoke test:**
- Walk through setup instructions as a new contributor.
- Are listed commands accurate? Would each step succeed?

**CLAUDE.md / project instructions:**
- Does project structure match the actual file tree?
- Are listed commands and scripts accurate?

**Any other .md files:**
- Read, determine purpose, cross-reference against diff.

Classify updates as:
- **Auto-update:** Factual corrections clearly warranted by the diff.
- **Ask user:** Narrative changes, section removal, large rewrites, ambiguous relevance.

## Step 3: Apply Auto-Updates

Make all clear, factual updates directly.

For each file modified, output: "README.md: added /new-feature to table, updated count from 9 to 10."

**Never auto-update:** README introduction/positioning, architecture philosophy, security model descriptions. Never remove entire sections.

## Step 4: Ask About Risky Changes

For each risky update, ask with context, the specific decision, a recommendation, and a "Skip" option.

## Step 5: CHANGELOG Voice Polish

If CHANGELOG was modified in this branch, review for voice:

- Lead with what the user can now DO — not implementation details.
- "You can now..." not "Refactored the..."
- Flag entries that read like commit messages.
- Internal changes go in a "For contributors" subsection.

**NEVER overwrite, replace, or regenerate CHANGELOG entries.** Polish wording only.

## Step 6: Cross-Doc Consistency

After individual audits, do a cross-doc pass:

1. Does README's feature list match CLAUDE.md?
2. Does ARCHITECTURE's components match CONTRIBUTING's structure?
3. Does CHANGELOG's version match VERSION file?
4. **Discoverability:** Is every doc file reachable from README or CLAUDE.md?
5. Flag contradictions. Auto-fix factual inconsistencies. Ask about narrative ones.

## Step 7: TODOS.md Cleanup

If TODOS.md exists:

1. Cross-reference diff against open items. Mark clearly completed items as done.
2. Check for stale item descriptions referencing changed components.
3. Check diff for TODO/FIXME/HACK comments representing deferred work — offer to add to TODOS.md.

## Output

```
DOCUMENTATION UPDATE
════════════════════
Files audited: N
Auto-updated:  M files
  - README.md: added feature X to table
  - CLAUDE.md: updated project structure
User decisions: K (N approved, M skipped)
Cross-doc: [consistent / N inconsistencies found]
TODOS: [N items completed, M items added]
```

If no updates needed: "Documentation is current — no updates needed."

## Next Step

Run `/sl-retro` at the end of the week to reflect on what was shipped.
