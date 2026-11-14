---
name: repository-work
description: Use when changing repository files, validating an implementation, writing repository prose, preparing a commit, or preparing a pull request. Skip read-only analysis.
---

# Repository work — bounded change contract

**Trigger:** repository files, implementation checks, commits or PRs. Skip read-only analysis. **Authority:** changes to files and their verification; not product policy, accepted laws, or agent scheduling.

```text
Inspect task + scoped AGENTS.md + source/config + git status/branch
  → Conflict safely isolated? No → Block without touching unrelated work
  → Yes → Classify change (Structural | Behavioral | Mixed)
    → Resolve approved contracts + relevant design/ADR
      → Plan smallest edit + tidy timing if needed
        → Update authoritative design graph when its contract changes
          → Edit → Verify actual boundaries → Review diff → Report
```

| Class | Meaning | Gate |
| --- | --- | --- |
| Structural | Intended to preserve observable behavior | Verify results, errors, effects, ordering, important timing, persistence and ownership. |
| Behavioral | Approved observable result changes | Retrieve `$requirements`, update applicable design contract and test. |
| Mixed | Both | Make steps separately reviewable when practical; no forced commits for trivial edits. |

**Tidying decision:** first when a small structural change measurably reduces immediate risk; after when implementing behavior first gives clarity; later/never when cost, unknowns or scope outweigh benefit. No unrelated opportunistic refactor, premature abstraction or changed requirement disguised as tidying. Unverified equivalence is a reported limit, never a pass.

## Before and during changes

Read relevant code and existing module design cards (`AGENTS.md`) before deletion; read accepted ADRs and `docs/security/` only when material to the task. Preserve preexisting uncommitted work and stop on unsafe conflicts. Prefer existing stack, nearby interfaces, code structure and project conventions. No edits to credentials, production data, secrets or access policy without authorization. Never weaken tests or requirements to pass. Use `$testing` for behavior; `$adr` only for consequential decisions; inspect `scripts/factory tools` or `references/OPTIONAL-TOOLS.md` when useful. For Git/PR/worktrees see `references/GIT_AND_PR.md`.

Update the authoritative design graph **before** changing shapes, invariants, graph edges, error strategies, resource owners or meaningful claims; update module cards only where this project maintains them. Respect declared `conform`/`translate` module boundaries. Requirement records change only with approved product behavior.

## Verification and completion

```text
Discover actual build/lint/test commands → smallest adequate checks
  → Recheck after conflict resolution or material changes
    → Final diff + evidence → Complete | Blocked | Partial(reason)
```

Do not invent commands or successes. Include command outcomes and log paths, explicitly say `not run` with reasons. Check affected contract/card/requirement references, justifications for lint suppressions, verified claims/IDs and actual paths. A 60-line module card is a readability heuristic, not a deletion mandate. No completion claim with unresolved required approval/checks.

For substantial repository prose use `references/STYLE.md` and `$content-writing`; preserve literal identifiers, names, commands and quotations. Verify links, paths, prerequisites, examples and claims; mark illustrative examples. Protect `docs/` under the root rule.
