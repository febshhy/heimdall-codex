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
N1 WRITE proofs/<rule>/LAWS.bend and proofs/<rule>/PROOF.bend
N2 RUN scripts/factory proof                   depends N1; gate=proof verifies N1
N3 WRITE src/rule.go                      depends N2; proof_gate=N2
N4 RUN conformance tests + review        depends N3; verifies N3
```

## Safe and unsafe autonomy

Autonomous within an authorized task: reading, planning, local edits, running repo tests, scoped delegated work, local documentation, fixing review failures.

A request to push or deliver authorizes the routine PR path through verified
trunk merge and cleanup unless the user limits scope. Follow the repository-work
Git and PR procedure and the target repository's governing delivery policy.
Installed Heimdall guidance does not carry this release repository's policy into
unrelated projects. An open, queued, or blocked PR remains pending when delivery
is required. Obtain authorization for effects outside that scope, including
deployments, releases, production data changes, and security policy changes.
Resolve material product ambiguity through the requirements skill.

## State

In-session coordinator state is primary. New delegated graphs initialize schema 3 with the immutable `candidate-bound/v1` review marker. Record one state/receipt per node with `scripts/factory begin/end/run` and reconcile with `scripts/factory validate`. Review gates require candidate, check, and affirmative verdict evidence bound to the WRITE and reviewer owners. Local evidence is not a trusted security attestation. Do not accept schema 2. Historical markerless schema-3 graphs remain inspectable, but their review notes cannot authorize new acceptance. Re-run interrupted work in a new graph after investigating the partial state. Never promote a running node to done by hand.

For review evidence, use `scripts/factory candidate-capture` to record the full
prospective Git tree and diff. If the capture is dirty and will later be
committed, use `candidate-bind` to verify the exact parent and tree, then obtain
the verdict for the bound identity. Record check logs with exact declared argv
arrays and SHA-256 digests. `review-check` can validate the evidence before
dispatch. A review-gated `run` validates the same inputs before acquiring its
lease. The accepted manifest, diff, check packet, verdict, and logs are copied
to graph evidence and checked again by `validate` and dependent nodes.

Each factory node snapshots its worktree independently. `READ` and `RUN` nodes
must keep the worktree root and `HEAD` unchanged between their own start and
finish snapshots. A schema-3 graph may have different `HEAD` values across
sequential nodes when authorized Git transitions occur between their leases.
For delivery, first accept a HEAD-stable `RUN` observation of the host merge.
The same authorized Luna controller can then perform checkout synchronization
and scoped task-ref cleanup outside an active node and lease. Keep the exact
command outcomes in a named handoff for a final HEAD-stable read-only node that
verifies the host merge, trunk and local checkout sync, and task-ref disposition.
Do not place checkout or ref transitions inside a `READ` or `RUN` node.
