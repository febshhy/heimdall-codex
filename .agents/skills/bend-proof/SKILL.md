---
name: bend-proof
description: Use Bend 2 laws as the reviewed formal product specification for explicitly selected proof-first work or stable, important modelable invariants. Prove before production implementation and verify conformance afterward.
---

# Bend 2 — approved law → proof → conformance

**Trigger:** explicitly requested proof-first scope or a consequential stable invariant that can be represented faithfully as a pure property/state transition. Not a universal gate for UI, network, operations, unresolved business intent or every feature.

**Authority:** operator-reviewed `LAWS.bend` is the formal product specification **within its selected scope**, replacing a duplicate PRD. `PROOF.bend` proves that law for its checked model; optional `SPEC.bend` defines a pure model. Neither a proof nor a passing smoke check approves a law or verifies separate production code. `$requirements` owns missing intent and approval.

```text
Intent + approved scope
  → Draft LAWS.bend (+ normative SPEC.bend assumptions, if used)
    → Expose quantified semantics, preconditions, exclusions, counterexamples
      → Operator reviews exact laws/assumptions
        → Accepted law → Write PROOF.bend + pure model
          → scripts/factory proof (actual pair, pinned Bend)
            → Pass → Production code → Conformance + effect/integration tests
            → Fail → Correct witness/non-normative model, or request law amendment
```

**Guards:** inspect accepted laws, relevant tests, `proofs/README.md` and `bend guide` first. Use stable law names under `proofs/<rule>/LAWS.bend`; `PROOF.bend` imports accepted laws. Avoid `@unsafe`, unchecked/foreign assumptions and TODOs in proof dependency closure. Never weaken an accepted law or normative model assumption just to pass. Amendments need renewed review and fresh proof/conformance evidence. Use project source review or another verifiable operator decision, not a mutable approval marker. No duplicate PRD or proof register.

**Failure/stop:** Bend unavailable, model unfaithful or proof required but infeasible → report blocked/request explicit rescope, never substitute tests silently. A smoke proof is installer-only. A law can be vacuous; test counterexamples and unintended implementations. A compiler/model/law change invalidates dependent evidence. Bind conformance to the actual application implementation, representation conversions, error paths and effects. Separate pure decisions from IO/time/network/rendering unless modeled explicitly.

**Output:** law → model/proof verdict → implementation path → conformance checks; report observed results, assumptions, unmodeled scope and risks. Keep proof assets compact and readable; no automatic writes to `docs/`.
