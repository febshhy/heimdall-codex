# Concurrency and commit boundaries — conditional extension

Use this with `../SKILL.md` when multiple actors can read or change the same mutable state. This extends the original graph method; it does not replace its shapes, invariants, or ownership model.

## Establish the concurrent model

1. Name each writer and the resource owner. Determine whether writers run in one process, multiple processes, multiple hosts, or a remote system.
2. Identify invariants that require *joint* observation or atomic mutation. A valid isolated `node(S, In)` does not guarantee that concurrent executions preserve a shared invariant.
3. State the ordering requirement: no order, per-key order, total order, or commutative operations. Do not require stronger ordering than the rules need.
4. Identify the linearization/commit point for important state changes, or state that the workflow is eventually consistent and define its convergence contract.
5. Select the simplest mechanism that enforces the contract: one owner/queue, database transaction, optimistic version check (compare-and-swap), conditional update, unique constraint, or lock. Treat distributed locks and global coordination as costly options with failure modes.
6. Define conflicts, timeouts, lease expiry, cancellation, crash recovery, and required observability as explicit errors or results. Do not assume a timeout means the write did not happen.

## Verification

- Exercise races with two concurrent writers and conflicting input; prove or check that the committed result preserves `Inv`.
- Check stale reads, lost updates, duplicate delivery, out-of-order results, restart and interruption where applicable.
- Test actual database isolation, lock behavior, or remote consistency separately from stand-in verification.
- Under retryable transaction errors, rerun the *whole decision and transaction* from a fresh valid snapshot, with bounded policy; do not replay an unsafe external effect.

Do not impose concurrency machinery on strictly single-owner, non-concurrent work. Applicable background: PostgreSQL current transaction isolation documentation, https://www.postgresql.org/docs/current/transaction-iso.html (re-check for the chosen database and version).
