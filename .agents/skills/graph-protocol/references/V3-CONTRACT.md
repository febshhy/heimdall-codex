# Graph Protocol schema 3 — shell boundary contract

The original ten-section `PROTOCOL.md` is canonical. This is only its JSON
encoding. The shell implementation **does not reinterpret** or modify the
worker's internal subgraph.

`schema_version` must be 3. `planned_nodes` must contain domain-owned task nodes.
Each node carries `depends_on`, `requires` (named predecessor outputs),
`produces`, optional `proof_gate`, `write_set`, `verifies`, `gate`, and
`delegation`:

- `A`: internal task nodes, per-node input/output names, and data-carrying edges;
  edges refer to actual producer/consumer names; the graph is acyclic.
- `E`: `wrong_context`, `missing_input`, or `misinterpretation` breakpoints with
  mitigation tied to an A node.
- `R`: `method`, exact `verification` argv arrays, `why`, and `inputs`.

The coordinator issues a packet with `delegated` and concrete `received`
predecessor outputs. A worker returns `{node_id, implemented, outputs, summary}`
with structured A/E/R. Graph comparison permits reordering of A nodes, A edges,
E entries and R input lists; the actual content must match. This comparison
verifies structure, not application semantics.

Operational CLI (Linux, Bash + jq + Git + GNU tools):

```sh
scripts/factory init --plan plan.json --graph .work/graphs/task.json
scripts/factory prompt --graph .work/graphs/task.json --node N1
scripts/factory begin --graph .work/graphs/task.json --node N1
scripts/factory end --graph .work/graphs/task.json --node N1 --return .work/N1.json
scripts/factory run --graph .work/graphs/task.json --node N2 --return .work/N2.json --review-note reviewed -- sh -c 'test -f src/feature.txt'
scripts/factory validate --graph .work/graphs/task.json
```

The plan is immutable after `init` and is bound to the Git common directory.
Evidence is stored in the sibling `GRAPH.evidence/` directory, which must be
Git-ignored when within the worktree. One active node per Git worktree across all graphs, using an atomic lease in
Git's worktree-specific metadata directory. Linked worktrees have independent
leases. Stale leases require inspection and explicit abort; the factory cannot
safely infer that a worker is dead. Short graph-local metadata locks protect
node state transitions. Worker execution is not scheduled by this CLI. Observations
wrap the boundary; A/E/R remains worker-owned between begin and end.

Only the current schema-3 contract is supported. Large structured JSON is passed
to jq through files, not command-line arguments.
