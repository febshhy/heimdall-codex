# Effects and recovery — conditional extension

Apply to stateful workflows with external effects, partial failure, important durability, or retries. The authoritative model remains `../SKILL.md`, especially §7–12.

## Effect results and uncertain outcomes

An effect result may be `ConfirmedSuccess(value)`, `ConfirmedFailure(error)`, or `UnknownOutcome(operationId)` when a remote call may have committed despite a dropped response. A transport timeout alone does not establish remote failure. Keep the operation ID and query/reconcile if the provider supports it.

- Before execution: decide whether the effect is safe to lose. If not, durably record the intended effect before acknowledging the enclosing state change.
- For a local database update plus outgoing event, consider a transactionally recorded outbox and an idempotent consumer. An outbox reduces lost intent; it does not guarantee exactly-once external delivery.
- For multi-step operations, define the compensation, undo, or resume policy, including what happens if compensation itself fails.
- For cancellation, distinguish stopping local work from undoing work already committed remotely. Release local resources on success, error, and cancellation.

## Idempotency contract

Define the key scope (actor / operation / target), parameter fingerprint, accepted response on repeat, retention period, concurrent duplicate handling, and what happens after expiry. The same key with materially different parameters should be rejected or follow a documented provider contract. Bound retries in count, elapsed time, and request rate; one layer owns them.

## Operational checks

Record an operation ID, lifecycle/attempt status, outcome and reconciliation evidence without leaking sensitive data. Verify duplicates, late responses, lost acknowledgments, process restart, partial commit, provider failures and recovery. A stand-in verifies the graph; a real provider test verifies its boundary contract.

Use this extension only when these failures could occur. No broker, workflow engine, or outbox is a default requirement.

Background: AWS Builders' Library, https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/ ; transactional outbox, https://microservices.io/patterns/data/transactional-outbox.html (source for pattern, not a universal design rule).
