---
name: requirements
description: Use when work depends on required product behavior or a new feature needs discovery. Retrieve controlling requirements before work; discover scenarios, dependencies and unknowns proportionally before changing requirements. Use the Question Gate for missing, conflicting, external, or costly-to-guess behavior.
---

# Requirements — approved behavior and discovery

**Authority:** Product meaning, observable obligations, constraints and approval status. Approved Baseline requirements and operator-reviewed `proofs/<rule>/LAWS.bend` control their respective scopes. `PROOF.bend` is model-level evidence, not desired behavior or operator approval. Do not force unmodelable UI/operations into laws or duplicate a PRD for reviewed laws.

```text
A Retrieve controlling scope
  → Already approved and unambiguous? hand off accepted obligation
  → Material new/ambiguous/multi-path? D Discover
    → Missing/conflicting/external/high-cost answer? C Question Gate
      → Answer approved? B Change → Baseline → handoff
      → Unknown/blocked? report and hold affected work
```

| Procedure | Input | Output | Guard |
| --- | --- | --- | --- |
| A Retrieve | Task + approved records | IDs/law names, status, boundaries, verification | Code is evidence, not approval. |
| B Change | Approved behavioral change | Atomic, testable `shall` + stable ID | No inferred policy or implementation-only record. |
| C Question Gate | Material unknown, conflict, external/time-sensitive claim, irreversible choice | Focused answer or blocker | Never ask for styling/naming already defined. |
| D Discover | New or consequential workflow | Scenarios, dependencies, unknowns, candidate obligations | Discovery is not approval. |

## A — Retrieve

Find exact law/requirement IDs first; otherwise search smallest likely approved source with `rg`/`grep`. Read the **full** relevant record, status, assumptions, counterexamples and non-formal constraints. Approved laws and Baselines bind only within their reviewed scope; conflicting authorities stop the affected work. Do not invent Provisional details or infer a requirement from current code. Inspect ADRs/research only where interpretation depends on them. For broad delegation save concise `.work/findings/` using `assets/FINDINGS_TEMPLATE.md`; project requirements directories are optional.

## D — Discover, then C or B

```text
Authorized intent / actors / stakes / constraints
  → Inspect accepted behavior + relevant source/tests/observations
    → Happy path + relevant unhappy, degraded, interrupt, concurrency,
       security and recovery paths + counterexamples
      → Classify dependency (product precondition | external authority |
           domain/runtime | work ordering), owner and failure
        → Condition + observable outcome + invariant + proposed check
          → Approved? B | Material unknown? C | Blocked/partial report
```

Scope exploration to risk: a small explicit request needs only relevant boundaries; avoid exhaustive questionnaires. Separate `Known | Unknown | Assumption | Decision`. Do not mistake implemented behavior for approved policy. Record which scenarios were considered or omitted and why; no checklist proves completeness. Read `references/DISCOVERY_AND_SCENARIOS.md` when warranted.

## B — Change

Retrieve affected records first. Non-trivial changes consult `references/REQUIREMENTS_METHOD.md`. One ID = one observable `shall` obligation, stable after references exist; record verifiable acceptance and cross-references. Unambiguous user-requested behavior authorizes scope and may become Baseline after testable recording. **Provisional** applies only to approved direction with unresolved acceptance detail; a merely proposed behavior is not approved. Implementation-only modifications are excluded. Preserve project conventions and review changed records; do not create a mandatory project directory.

Formalization: present exact draft `LAWS.bend` and normative `SPEC.bend` assumptions for operator review. A proof cannot approve/amend a law. If approved law semantics are wrong, return to its owner; never weaken it during proof or implementation.

## C — Question Gate

Use one focused question or source investigation for correctness-critical missing answers, conflicts, external/time-changing facts, and high reversal cost. For complex independent research use `$evidence-research` or bounded native Codex READ agents, not an external `codex exec` pipeline. Findings are evidence, never automatic Baseline. Store enduring research under project `docs/` only with explicit documentation authorization; otherwise keep scratch under `.work/`. Pass accepted behavior to Software/GUI Design Thinking for implementation modeling.
