# Factory lifecycle and delegation examples

The dependency graph is driven by actual task requirements, not by a rigid agent count. The primary agent chooses nodes and records explicit edges.

## Example: multi-module feature

```text
N1 READ requirements and current code contracts
N2 READ architecture and risk analysis          (may run alongside N1)
N3 WRITE service changes         depends N1,N2; owns src/service/**
N4 WRITE UI changes              depends N1,N2; owns src/ui/**
N5 RUN service tests             depends N3
N6 RUN UI tests                  depends N4
N7 RUN independent code review  depends N3,N4; verifies N3,N4; different owner
N8 RUN integration/build tests  depends N5,N6,N7
```

Each delegated WRITE must be independently reviewed and scoped to exclusive paths. The final integration phase remains owned by the main coordinator; if it changes tracked code after review, add and verify a new WRITE node.

## Example: Bend scoped proof rule

```text
N1 WRITE proofs/rule.bend
N2 RUN scripts/factory proof ...               depends N1; gate=proof verifies N1
N3 WRITE src/rule.go                      depends N2; proof_gate=N2
N4 RUN conformance tests + review        depends N3; verifies N3
```

## Safe and unsafe autonomy

Autonomous within an authorized task: reading, planning, local edits, running repo tests, scoped delegated work, local documentation, fixing review failures.

Require approval: deployments, remote writes, deletion/migration of production data, publishing, external credentials transfer, changing security policy, materially ambiguous product behavior. Report pending approval rather than claiming end-to-end delivery.

## State

In-session coordinator state is primary. For delegated writes, initialize schema 3 from a coordinator-approved plan, record one state/receipt per node with `scripts/factory begin/end/run` and reconcile with `scripts/factory validate`. Local evidence is not a trusted security attestation. Do not accept schema 2. Old graph schemas are unsupported. Re-run interrupted work in a new graph after investigating the partial state; never promote a running node to done by hand.
