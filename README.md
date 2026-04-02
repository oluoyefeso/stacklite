# stacklite

The review intelligence from [gstack](https://github.com/garrytan/gstack), zero dependencies. Nine commands covering the full sprint lifecycle — think, plan, build, review, test, ship, reflect — as plain markdown files for your AI coding IDE.

No binaries. No runtime. No telemetry. Just markdown.

## Supported IDEs

| IDE | Location | How to invoke |
|-----|----------|---------------|
| **Claude Code** | `.claude/commands/sl-*.md` | Type `/sl-` in chat |
| **VS Code Copilot** | `.github/prompts/sl-*.prompt.md` | Type `#` or `/` in Copilot Chat |
| **Cursor** | `.cursor/rules/sl-*.mdc` | Auto-attached by agent or `@Rules` |
| **Windsurf** | `.windsurf/rules/sl-*.md` | Auto-attached by Cascade |

## Install

### Option 1: Ask your AI

Paste this into your AI coding assistant (Claude Code, Cursor, Copilot, Windsurf, or any IDE with an AI agent):

> Install stacklite into this project. Clone https://github.com/oluoyefeso/stacklite.git to /tmp/stacklite. Detect which IDE I'm using by checking which of these directories exist in my project: .claude/, .github/, .cursor/, .windsurf/. If none exist, ask me which IDE I use. Then copy the matching target folder:
>
> - Claude Code: `cp -r /tmp/stacklite/targets/claude-code/.claude .`
> - VS Code Copilot: `cp -r /tmp/stacklite/targets/copilot/.github .`
> - Cursor: `cp -r /tmp/stacklite/targets/cursor/.cursor .`
> - Windsurf: `cp -r /tmp/stacklite/targets/windsurf/.windsurf .`
>
> After copying, list the commands that were installed and briefly explain each one. Clean up with `rm -rf /tmp/stacklite`.

That's it. Your AI agent handles the rest.

### Option 2: Copy the files manually

```bash
git clone https://github.com/oluoyefeso/stacklite.git /tmp/stacklite
```

Then copy the folder for your IDE:

```bash
# Claude Code
cp -r /tmp/stacklite/targets/claude-code/.claude .

# VS Code Copilot
cp -r /tmp/stacklite/targets/copilot/.github .

# Cursor
cp -r /tmp/stacklite/targets/cursor/.cursor .

# Windsurf
cp -r /tmp/stacklite/targets/windsurf/.windsurf .
```

## Commands

### Think + Plan
| Command | What it does |
|---------|-------------|
| `/sl-plan` | Product thinking before code. Six forcing questions for startups, design partner mode for side projects. Premise challenge, alternatives generation, design doc output. |
| `/sl-eng-review` | Architecture, code quality, tests, performance review of a plan. Scope challenge, ASCII coverage diagrams, interactive section-by-section walkthrough. |

### Review + Test
| Command | What it does |
|---------|-------------|
| `/sl-review` | Pre-landing diff review. SQL safety, race conditions, LLM trust boundaries, shell injection, enum completeness + testing, maintainability, API contracts, data migration checks. Fix-first: auto-fixes mechanical issues, asks about ambiguous ones. |
| `/sl-secure` | OWASP Top 10 + STRIDE threat model. Attack surface census, secrets archaeology, dependency supply chain, CI/CD pipeline, webhook audit, LLM security. Confidence-gated with false positive filtering. |
| `/sl-perf` | Performance-focused review. N+1 queries, missing indexes, algorithmic complexity, bundle size, rendering performance, missing pagination, async blocking. |

### Ship + Reflect
| Command | What it does |
|---------|-------------|
| `/sl-ship` | Merge base, run tests, coverage audit, pre-landing review, commit, push, create PR. One command from "done coding" to "PR open." |
| `/sl-investigate` | Systematic root-cause debugging. Iron law: no fixes without investigation. 5-phase workflow with 3-strike escalation rule. |
| `/sl-retro` | Weekly retrospective from git history. Metrics, session detection, commit patterns, hotspot analysis, per-author deep dives, shipping velocity. |
| `/sl-doc` | Auto-update all docs after shipping. Cross-references diff against every .md file, fixes factual drift, polishes CHANGELOG voice. |

## The Sprint

stacklite follows a natural process. Each command suggests the next one when it finishes:

```
/sl-plan → /sl-eng-review → [build] → /sl-review + /sl-secure + /sl-perf → /sl-ship → /sl-doc → /sl-retro
   ↑                                                                                                │
   └────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Each command feeds the next. `/sl-plan` produces a design doc that `/sl-eng-review` reviews. `/sl-review` catches bugs that `/sl-ship` verifies are fixed. `/sl-doc` updates what `/sl-ship` changed. `/sl-retro` reflects on what was shipped and suggests what to `/sl-plan` next.

## What's included vs gstack

### Kept (the valuable parts)
- All review checklists and the specific patterns to look for
- Scope challenge, complexity checks, cognitive patterns
- Fix-first review pattern (auto-fix mechanical, ask about ambiguous)
- ASCII test coverage diagrams
- Confidence calibration (1-10 on every finding)
- Scope drift detection
- OWASP Top 10 + STRIDE threat model with 22 false-positive exclusion rules
- 7 specialist domains (testing, maintainability, security, performance, API contracts, data migration, red team) inlined into /sl-review
- Six forcing questions for product thinking
- Systematic debugging with 3-strike escalation
- Full ship automation (test, review, PR)
- Git-based retrospectives with session detection

### Stripped (gstack infrastructure)
- Bun runtime and 34+ compiled binaries
- Telemetry, analytics, session tracking
- Learnings/memory system across sessions
- Upgrade checks and auto-updater
- Browser automation (/browse, /qa, /canary, /benchmark)
- Codex/outside voice integration
- Specialist subagent dispatch (inlined instead)
- Greptile integration
- Design tools (/design-consultation, /design-shotgun, /design-review)
- Context recovery after compaction
- GStack persona/voice branding
- Contributor mode

## Contributing

The canonical source for each command lives in `commands/`. The IDE-specific copies in `targets/` are manually synced with frontmatter appropriate for each IDE. When editing a command:

1. Edit the canonical file in `commands/`
2. Copy the change to all 4 target directories:
   - `targets/claude-code/.claude/commands/` (no frontmatter)
   - `targets/copilot/.github/prompts/` (has `mode` + `description` frontmatter)
   - `targets/cursor/.cursor/rules/` (has `description` + `alwaysApply` frontmatter)
   - `targets/windsurf/.windsurf/rules/` (has `trigger` + `description` frontmatter)

All command files use the `sl-` prefix (e.g., `sl-plan.md`, `sl-review.md`).

## Upgrading from v2

v3 renamed all commands with an `sl-` prefix to avoid clashing with IDE built-in commands (e.g., Claude Code's `/plan` mode). Delete the old command files from your project and re-copy from the matching target folder.

## Customise

These are plain markdown files. Edit them for your team:
- Add framework-specific checks to `/sl-review`
- Adjust test coverage expectations in `/sl-eng-review`
- Add your own forcing questions to `/sl-plan`
- Change engineering preferences to match your style

## Optional: routing rules (Claude Code)

Copy the routing section from `CLAUDE.md.example` into your project's `CLAUDE.md` so Claude Code knows when to suggest which command.

## License

MIT. Derived from [gstack](https://github.com/garrytan/gstack) by Garry Tan (also MIT).
