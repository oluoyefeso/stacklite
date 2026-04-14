# Changelog

## [3.1.0] - 2026-04-14

Synced review intelligence improvements from gstack v0.15–v0.16.

### Added

- **Anti-skip rule** on all review commands (`/sl-review`, `/sl-eng-review`, `/sl-secure`, `/sl-perf`). Prevents models from condensing, abbreviating, or skipping review passes — the most common failure mode in AI-driven code review.
- **Adversarial review pass** in `/sl-review` (Step 6). After the structured review, a fresh pass asks "what's the worst thing that happens in production?" — focusing on blast radius, concurrency, boundary conditions, and integration breakage.
- **Plan completion audit** in `/sl-ship` (Step 5). Auto-discovers plan/design doc files, extracts actionable items, compares against the diff, and gates shipping on completion. Prevents shipping code that doesn't match what was planned.
- **Plan completion section** in `/sl-ship` PR body template.

### Changed

- `/sl-ship` steps renumbered (5→10) to accommodate plan completion audit insertion.

## [3.0.0] - 2026-04-02

**Breaking change:** All commands renamed with `sl-` prefix to avoid clashing with IDE built-in commands (e.g., Claude Code's `/plan` mode).

### Changed

- `/plan` → `/sl-plan`, `/review` → `/sl-review`, `/ship` → `/sl-ship`, and all other commands now prefixed with `sl-`.
- All cross-references between commands updated.
- README updated with new command names and upgrade instructions.

### Migration

Delete old command files from your project and re-copy from the matching target folder.

## [2.0.0] - 2026-04-02

Every command now tells you what to run next. The sprint cycle is a connected loop, not a list of independent tools.

### Added

- **Command chaining hints.** All 9 commands now include a "Next Step" section suggesting which command to run next. The sprint cycle flows naturally: plan → eng-review → review → ship → doc → retro → plan.
- **Sprint cycle diagram** in README with visual loop showing how commands connect.
- **Contributing section** in README explaining how to edit commands and sync IDE targets.
- **VERSION file** (2.0.0).
- **TODOS.md** with deferred roadmap items (build automation P2, workflow protocol P3).
- **CHANGELOG.md** (this file).

### Changed

- Standardized plan.md's "Phase 7: Review Chaining" to "Next Step" for consistency with other commands.
