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

## Recorded readiness and coordinator acceptance

`ready` checks that the node has not started and that predecessor returns and
receipts satisfy the recorded gates. `validate` checks the completed graph
against the observed evidence. Before dispatch, the coordinator also checks
the actual diff, test results, and independent review where required. A review
note is recorded evidence supplied to the CLI. Review quality and independence
remain coordinator judgments. Hold a successor if its required evidence is
missing, stale, or disputed, even when the CLI reports readiness.

## Recover an interrupted node

1. Inspect the recorded status, worker state, owning worktree, and partial diff.
   If the worker is still active, wait or explicitly stop it before recovery.
   Preserve its edits and the existing evidence.
2. If a node is still recorded as running after the worker has stopped, abort
   it from the owning worktree. The command marks the node failed and releases
   its matching lease.

   ```sh
   scripts/factory status --graph .work/graphs/task.json
   scripts/factory abort --graph .work/graphs/task.json --node N2 --reason 'Worker exited before returning evidence'
   ```

3. Keep the old graph for diagnosis. If work can continue, reconcile any
   partial edits with the intended scope and initialize a fresh schema-3 plan
   at a new graph path. A started node cannot be restarted in place, and a plan
   change also requires a fresh graph. Verify the new graph's inputs against
   current source and observed evidence before dispatch.

## Candidate-bound review contract

`init` stamps newly created schema-3 graphs with the immutable
`review_contract: "candidate-bound/v1"` marker and includes it in
`plan_sha256`. Do not remove or change it. Historical schema-3 graphs without
the marker can still use `status` and inspect their receipts. Their historical
review notes do not authorize new review-gated acceptance.

Candidate capture and review use these commands:

```sh
scripts/factory candidate-capture --graph .work/graphs/task.json --node N1 \
  --base <base-commit> --manifest .work/review/candidate.json \
  --diff-out .work/review/candidate.diff
scripts/factory candidate-bind --manifest .work/review/candidate.json \
  --commit <later-commit> --output .work/review/bound-candidate.json
scripts/factory review-check --graph .work/graphs/task.json --node N2 \
  --candidate-manifest .work/review/bound-candidate.json \
  --check-evidence .work/review/checks.json \
  --review-verdict .work/review/verdict.json
scripts/factory run --graph .work/graphs/task.json --node N2 \
  --candidate-manifest .work/review/bound-candidate.json \
  --check-evidence .work/review/checks.json \
  --review-verdict .work/review/verdict.json \
  --return .work/N2.json --review-note 'candidate reviewed' -- <declared argv>
```

The candidate collector writes a full prospective Git tree using a temporary
index outside the worktree. It leaves the real index intact and captures staged,
unstaged, untracked, deleted, mode, symlink, and NUL-delimited path data. It
captures base and HEAD commits, the real index tree, status and diff digests,
and a full base-to-candidate diff. It repeats the capture and rejects movement.
All candidate paths must fit the target WRITE node's `write_set`. Unmerged
indexes and conflict status are rejected.

At successful WRITE completion in a new candidate-bound graph, the receipt also
records `finish_tree`: the exact prospective tree SHA plus its base and finish
HEADs, changed paths, real index tree, status and staged/unstaged diff digests,
the stable finish-snapshot digest, and a canonical identity digest. The
temporary-index capture is repeated and must match the receipt's finish
snapshot and scope. Review requires the candidate tree and changed paths to
equal this WRITE finish binding. This applies to a dirty candidate, a dirty
candidate later bound to a commit, and a directly captured clean commit.
Committing an exact dirty candidate remains valid when the commit has the
captured WRITE finish HEAD as its sole parent and the same tree.

New bound plans also enforce review ordering at initialization and when
loading the graph. Every transitive descendant of a reviewed WRITE must be the
review gate itself, a non-WRITE predecessor of every gate for that WRITE, or a
descendant of every such gate. This permits check/evidence preparation before
review while preventing another consumer from running on the WRITE output
without consuming its review result. With multiple review gates for one WRITE,
pre-review evidence must precede all gates and downstream consumers must follow
all gates.

A clean candidate binds directly to its current commit. A dirty candidate can
be bound later only to a single-parent commit whose parent is the captured HEAD
and whose tree exactly matches the captured prospective tree. Review the bound
manifest after binding. This keeps the eventual commit, parent, and base in the
review identity.

Check evidence is JSON with `schema_version: 1`, `candidate_identity`,
`candidate_manifest_sha256`, and `checks`. Each check contains the exact `argv`
array declared in the review node's `delegation.R.verification`, `exit_code: 0`,
`log_path` relative to the candidate worktree, and `log_sha256`. The factory
checks every log digest and requires each declared verification argv.

The independent review verdict is JSON with `schema_version: 1`,
`verdict: "accept"`, `node_id`, `write_node`, `reviewer_owner`,
`candidate_identity`, `candidate_manifest_sha256`, `evidence_sha256` (the
candidate diff digest), `checks_sha256`, and `findings`. The verdict must name
the review node owner and a different WRITE owner. The factory checks identity
and digests. It does not authenticate the human or agent named as reviewer.
Review-gated `run` validates all inputs before acquiring a lease or executing
the declared command. Accepted candidate, diff, check, verdict, and log bytes
are copied into graph evidence and rechecked by `validate` and downstream
dependency consumption. Local hashes establish consistency, not external
attestation.

Start a candidate-bound WRITE in a clean isolated worktree, or limit existing
dirty state to the WRITE node's declared scope. For distinct sequential WRITEs,
integrate each accepted predecessor into the new base before starting the next
candidate-bound graph. Preserve unrelated edits outside the candidate worktree;
never discard them to make a candidate clean.

Do not re-use evidence after base, candidate identity, check argv, or check log
bytes change. Capture a fresh candidate and collect checks and verdict again.
Missing, malformed, rejected, or stale prerequisites fail before a command
starts. Normal check nodes may run before an independent review node so the
reviewer can inspect their candidate-bound results.
