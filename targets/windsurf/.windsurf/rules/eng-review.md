---
trigger: "model_decision"
description: "Engineering plan review — activate when user asks to review architecture, tests, or technical plans"
---

# Engineering Plan Review

Review this plan/feature thoroughly before any code is written. For every issue, explain concrete tradeoffs, give an opinionated recommendation, and ask for input before assuming a direction.

## Engineering Preferences
* DRY is important — flag repetition aggressively.
* Well-tested code is non-negotiable.
* "Engineered enough" — not under-engineered (fragile) and not over-engineered (premature abstraction).
* Handle more edge cases, not fewer. Thoughtfulness > speed.
* Explicit over clever. Minimal diff.
* ASCII art diagrams for data flow, state machines, dependency graphs, processing pipelines.

## Cognitive Patterns
1. **Blast radius instinct** — "what's the worst case and how many systems does it affect?"
2. **Boring by default** — Use proven technology. Save innovation tokens for what matters.
3. **Incremental over revolutionary** — Strangler fig, not big bang. Refactor, not rewrite.
4. **Systems over heroes** — Design for tired humans at 3am.
5. **Reversibility preference** — Feature flags, incremental rollouts. Make being wrong cheap.
6. **Essential vs accidental complexity** — "Is this solving a real problem or one we created?"
7. **Make the change easy, then make the easy change** — Refactor first, implement second.

## Step 0: Scope Challenge

Before reviewing anything:

1. **What existing code already solves each sub-problem?** Can we reuse existing flows?
2. **What is the minimum set of changes?** Flag work that could be deferred. Be ruthless about scope creep.
3. **Complexity check:** If the plan touches >8 files or introduces >2 new classes/services, challenge whether the same goal can be achieved with fewer moving parts.
4. **Search check:** For each pattern or infrastructure the plan introduces:
   - Does the framework have a built-in?
   - Is this current best practice?
   - Are there known footguns?
5. **Completeness check:** Is this the complete version or a shortcut? With AI-assisted coding, the cost of completeness is dramatically cheaper. Recommend the complete version when the delta is small.

If the complexity check triggers, recommend scope reduction — explain what's overbuilt, propose a minimal version, ask whether to reduce or proceed.

**Once scope is agreed, commit fully.** Do not re-argue in later sections.

## Review Sections

Work through each section interactively. Present issues individually with options, recommendations, and reasoning. Proceed to next section only after all issues are resolved.

### 1. Architecture Review
Evaluate:
* System design and component boundaries — draw ASCII diagrams.
* Dependency graph and coupling concerns.
* Data flow patterns and bottlenecks.
* Scaling characteristics and single points of failure.
* Security architecture (auth, data access, API boundaries).
* For each new codepath, describe one realistic production failure scenario.

**STOP.** Present each issue individually.

### 2. Code Quality Review
Evaluate:
* Code organization and module structure.
* DRY violations — be aggressive.
* Error handling patterns and missing edge cases (call out explicitly).
* Technical debt hotspots.
* Over/under-engineering relative to preferences.
* Existing ASCII diagrams in touched files — still accurate?

**STOP.** Present each issue individually.

### 3. Test Review

100% coverage is the goal. Evaluate every codepath and ensure the plan includes tests.

**Step 1 — Trace every codepath.** For each planned component, follow data through every branch, error path, and function call. Draw the execution as an ASCII diagram.

**Step 2 — Map user flows and error states:**
- User flows: what sequence of actions touches this code?
- Interaction edge cases: double-click, navigate away mid-operation, stale data, slow connection, concurrent actions
- Error states: clear messages vs silent failures, recovery paths
- Boundary states: zero, max, empty, single-element

**Step 3 — Check each branch against existing tests:**
- ★★★ Tests behavior with edge cases AND error paths
- ★★  Tests correct behavior, happy path only
- ★   Smoke test / trivial assertion

**E2E vs Unit decision:**
- E2E: user flow spanning 3+ components, integration points where mocking hides failures, auth/payment/data-destruction flows
- Unit: pure functions, internal helpers, single-function edge cases

**Step 4 — Output ASCII coverage diagram:**
```
CODE PATH COVERAGE
===========================
[+] src/services/billing.ts
    ├── processPayment()
    │   ├── [★★★ TESTED] Happy path + timeout — billing.test.ts:42
    │   ├── [GAP]         Network timeout — NO TEST
    │   └── [GAP]         Invalid currency — NO TEST
    └── refundPayment()
        ├── [★★  TESTED] Full refund — billing.test.ts:89
        └── [★   TESTED] Partial refund (non-throw only)

USER FLOW COVERAGE
===========================
[+] Payment checkout flow
    ├── [★★★ TESTED] Complete purchase — checkout.e2e.ts:15
    ├── [GAP] [→E2E] Double-click submit
    └── [GAP]         Navigate away during payment

─────────────────────────────────
COVERAGE: 5/10 paths (50%)
GAPS: 5 paths need tests (1 needs E2E)
─────────────────────────────────
```

**Step 5 — Add missing tests to the plan.** For each GAP: test file, assertions, unit vs E2E.

**STOP.** Present each issue individually.

### 4. Performance Review
Evaluate:
* N+1 queries and database access patterns.
* Memory-usage concerns.
* Caching opportunities.
* Slow or high-complexity code paths.

**STOP.** Present each issue individually.

## Confidence Calibration

Every finding includes a confidence score (1-10):
- 9-10: Verified by reading specific code. Show normally.
- 7-8: High confidence pattern match. Show normally.
- 5-6: Moderate, could be false positive. Show with caveat.
- 3-4: Low confidence. Appendix only.

Format: `[SEVERITY] (confidence: N/10) file:line — description`

## Completion Summary
```
ENG REVIEW SUMMARY
═══════════════════
Architecture: X issues found, Y resolved
Code Quality:  X issues found, Y resolved
Tests:         Coverage X% → Y% (Z gaps remain)
Performance:   X issues found, Y resolved
STATUS: CLEARED / NOT CLEARED
[Next steps]
```
