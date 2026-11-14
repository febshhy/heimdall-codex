---
name: testing
description: Use when verifying behavior changes or consequential behavior-preserving refactors, including state machines, boundary contracts, regressions, invariants, and property-based tests. Keep checks linked to meaningful claims and stable boundaries.
---

# Testing — claim → check → evidence

**Authority:** `$testing` selects verification and reports observed evidence; it does not approve product requirements, Bend laws, or changes to GUI/domain behavior.

```text
Claim (approved requirement | invariant | defect | relevant contract)
  → Select stable boundary and primary check
    → Resolve real command and prerequisites
      → Execute → Passed(evidence) | Failed(evidence) | Inconclusive(reason)
        → Report supported scope, gaps, command, exit result, log
```

## Selection contract

Prefer one primary check per claim at a stable boundary; do not duplicate a claim at the same boundary or chase coverage numbers.

| Check | Select when |
| --- | --- |
| Conformance | Approved requirement/external contract or a proven Bend model must match production; compare with model when applicable. |
| Behavioral | Observable module `index` or other stable boundary behavior. |
| Smoke | One critical end-to-end path per thin slice. |
| Regression | Reproduce a real bug before its fix; retain its check. |
| Fuzz/property | Invariants, state sequences, parsers or combinatorial domains; define property, generators, reproducible seeds, bounded runtime. Bend is optional. |
| Unit | Important pure-decision edge cases that boundary tests cannot isolate efficiently; say why. |

**Guards:** link each check to a requirement, invariant, meaningful claim/card ID or defect. Review orphan tests and unverified requirements; lack of a card ID alone never justifies deleting a useful regression. Test through module `index` unless internals are a required contract. Do not mock the module under test. Stand-ins are only for external boundaries, and cannot establish behavior of the real boundary.

## Execution and reporting

```text
Read AGENTS.md Commands + actual repository configuration
  → Compile/build first if required (unless that check itself is the build)
  → Run smallest sufficient checks
  → Record outcome and relevant logs
  → Re-run affected checks after consequential changes
```

Never invent commands. If tooling is missing, use the project's native stack to scaffold an appropriate check when authorized; record its command under `Commands`. For noisy commands use `scripts/factory log <suite-name> -- <command> [args...]`; inspect saved failures. Do not rerun just to display output; rerun failures to investigate nondeterminism and keep both logs. Flakiness is a defect. Report `not run` with reason rather than implying success.

### Structural changes

Behavior preservation is an **intention**, not a proved result. Before and after consequential tidying, check relevant outputs, errors, effects, ordering, persistence, concurrency, lifetime and performance contracts. Use focused existing checks or source-grounded characterization tests. Keep meaningful structural and behavioral steps separately verifiable when practical. Never approve snapshots or weaken checks merely to pass; if equivalence is unestablished, report its scope and risk. Purely cosmetic edits do not demand new tests without a credible failure mode.

### GUI and motion (conditional)

Check affected real GUI states in an available browser/native environment; consult `../gui-design-thinking/references/RENDERING-AND-MOTION.md`. Screenshot → visual state only; interaction assertion → behavior; measured frame trace → motion. Record target/revision and review baseline updates. An unavailable runtime is `not verified`, not evidence. For vector motion inspect raster-frame/embedded-image/vector-frame bloat, geometry, keyframes, size, scaling, clipping, reduced-motion and interruption. For material 3D inspect declared PBR/NPR/hybrid intent, geometry/material/texture cost, actual input/depth/legibility, static/2D fallback, runtime memory and frame pacing. Use actual target budgets and profiling when relevant; neither screenshot nor a material label establishes cross-platform correctness.

### Bend scope (conditional)

```text
Reviewed LAWS.bend + actual PROOF.bend
  → scripts/factory proof: passed for the law/proof pair (not smoke)
    → Production implementation
      → Model-to-production conformance + unhappy/effect paths
```

Changes to a law, normative model assumptions, compiler or relevant implementation invalidate affected evidence. A model proof does not certify external effects or independent production code. Report uncovered behavior explicitly.

**Acceptance guard:** `claim accepted ⇒ observed relevant evidence at inspected revision`. Passing tests support their tested scope, not comprehensive correctness.
