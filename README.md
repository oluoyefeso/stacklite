# stacklite

The review intelligence from [gstack](https://github.com/garrytan/gstack), zero dependencies. Nine commands covering the full sprint lifecycle — think, plan, build, review, test, ship, reflect — as plain markdown files for your AI coding IDE.

No binaries. No runtime. No telemetry. Just markdown.

## Supported IDEs

| IDE | Location | How to invoke |
|-----|----------|---------------|
| **Claude Code** | `.claude/commands/*.md` | Type `/` in chat |
| **VS Code Copilot** | `.github/prompts/*.prompt.md` | Type `#` or `/` in Copilot Chat |
| **Cursor** | `.cursor/rules/*.mdc` | Auto-attached by agent or `@Rules` |
| **Windsurf** | `.windsurf/rules/*.md` | Auto-attached by Cascade |

## Install

### Option 1: Copy the files

Clone this repo, then copy the folder for your IDE into your project:

```bash
git clone https://github.com/oluoyefeso/stacklite.git /tmp/stacklite
```

**Claude Code:**
```bash
cp -r /tmp/stacklite/targets/claude-code/.claude .
```

**VS Code Copilot:**
```bash
cp -r /tmp/stacklite/targets/copilot/.github .
```

**Cursor:**
```bash
cp -r /tmp/stacklite/targets/cursor/.cursor .
```

**Windsurf:**
```bash
cp -r /tmp/stacklite/targets/windsurf/.windsurf .
```

### Option 2: Ask your AI

Paste this into Claude Code, Cursor, or any AI coding assistant:

> Clone https://github.com/oluoyefeso/stacklite.git to /tmp/stacklite and copy the appropriate target files into my project. Detect which IDE we're in and pick the right target folder.

## Commands

### Think + Plan
| Command | What it does |
|---------|-------------|
| `/plan` | Product thinking before code. Six forcing questions for startups, design partner mode for side projects. Premise challenge, alternatives generation, design doc output. |
| `/eng-review` | Architecture, code quality, tests, performance review of a plan. Scope challenge, ASCII coverage diagrams, interactive section-by-section walkthrough. |

### Review + Test
| Command | What it does |
|---------|-------------|
| `/review` | Pre-landing diff review. SQL safety, race conditions, LLM trust boundaries, shell injection, enum completeness + testing, maintainability, API contracts, data migration checks. Fix-first: auto-fixes mechanical issues, asks about ambiguous ones. |
| `/secure` | OWASP Top 10 + STRIDE threat model. Attack surface census, secrets archaeology, dependency supply chain, CI/CD pipeline, webhook audit, LLM security. Confidence-gated with false positive filtering. |
| `/perf` | Performance-focused review. N+1 queries, missing indexes, algorithmic complexity, bundle size, rendering performance, missing pagination, async blocking. |

### Ship + Reflect
| Command | What it does |
|---------|-------------|
| `/ship` | Merge base, run tests, coverage audit, pre-landing review, commit, push, create PR. One command from "done coding" to "PR open." |
| `/investigate` | Systematic root-cause debugging. Iron law: no fixes without investigation. 5-phase workflow with 3-strike escalation rule. |
| `/retro` | Weekly retrospective from git history. Metrics, session detection, commit patterns, hotspot analysis, per-author deep dives, shipping velocity. |
| `/doc` | Auto-update all docs after shipping. Cross-references diff against every .md file, fixes factual drift, polishes CHANGELOG voice. |

## The Sprint

stacklite follows a natural process. Each command suggests the next one when it finishes:

```
/plan → /eng-review → [build] → /review + /secure + /perf → /ship → /doc → /retro
  ↑                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘
```

Each command feeds the next. `/plan` produces a design doc that `/eng-review` reviews. `/review` catches bugs that `/ship` verifies are fixed. `/doc` updates what `/ship` changed. `/retro` reflects on what was shipped and suggests what to `/plan` next.

## What's included vs gstack

### Kept (the valuable parts)
- All review checklists and the specific patterns to look for
- Scope challenge, complexity checks, cognitive patterns
- Fix-first review pattern (auto-fix mechanical, ask about ambiguous)
- ASCII test coverage diagrams
- Confidence calibration (1-10 on every finding)
- Scope drift detection
- OWASP Top 10 + STRIDE threat model with 22 false-positive exclusion rules
- 7 specialist domains (testing, maintainability, security, performance, API contracts, data migration, red team) inlined into /review
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

## Customise

These are plain markdown files. Edit them for your team:
- Add framework-specific checks to `/review`
- Adjust test coverage expectations in `/eng-review`
- Add your own forcing questions to `/plan`
- Change engineering preferences to match your style

## Optional: routing rules (Claude Code)

Copy the routing section from `CLAUDE.md.example` into your project's `CLAUDE.md` so Claude Code knows when to suggest which command.

## License

MIT. Derived from [gstack](https://github.com/garrytan/gstack) by Garry Tan (also MIT).
