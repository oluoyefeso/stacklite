# TODOs

## P2: Build automation (generate.sh / orchestrator)
**What:** A script that generates IDE-specific target files from canonical commands/ + templates/.
**Why:** Eliminates manual 4x sync when editing commands. Currently ~25 seconds of copy-paste per edit, monthly frequency. Becomes worth automating when edit frequency increases or IDE count grows.
**Context:** Reviewed in CEO review (2026-04-02). Two outside voices said "not now" — the manual overhead is low for monthly edits. Revisit when there are community contributors or >4 IDEs.
**Depends on:** User demand / contribution frequency increase.

## P3: Workflow protocol with DAG execution
**What:** Define engineering workflows as a directed graph. Each node is a command, edges are gates (review must pass before ship). Community contributes workflow definitions.
**Why:** Category-defining — nobody else has workflow-as-code for AI IDEs. Composable, versionable, shareable processes.
**Context:** Proposed by independent Claude subagent during CEO review office-hours session. Deferred as premature for current scale (single maintainer + friends). Revisit when orchestrator (P2) is stable and there's proven user demand.
**Depends on:** P2 orchestrator, proven user demand.
