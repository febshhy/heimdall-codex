# Data modeling — discover facts, then represent them

Use with [Database Design](../SKILL.md), especially when defining persisted shapes, relationships or data contracts. The domain meaning and invariants come from [Software Design Thinking](../../software-design-thinking/SKILL.md). This is an exploration, not a fixed requirement to use relational tables.

## From domain to stored facts

Ask for a small representative instance and write:

1. **Entity and identity:** stable business identity versus surrogate/physical key; natural-key volatility; uniqueness across tenant, time and version; collations/case/Unicode.
2. **Relationships:** 1:1, 1:N, M:N, optional/required, ownership vs reference, referential actions on deletion, cyclic creation.
3. **Facts and derivations:** authoritative input, externally sourced fact, event/history, mutable current state, materialized projection, cache, UI draft. A derived total must have one source and reconciliation strategy if materialized.
4. **Temporal meaning:** event time versus ingestion/commit time; valid time versus transaction time when historical queries demand both; time zone, precision, late arrivals and retention.
5. **Security/tenant scope:** isolation boundary and authorization on all query/write paths; encryption, PII, erasure, audit requirements. Constraints do not replace access control.
6. **Invariants:** distinguish column/type constraints, uniqueness, foreign keys, checks, cross-row or transactional invariants, cross-service guarantees. Name who enforces each under concurrency.

Example (illustrative, not a prescribed schema):

```text
Order(id, customerId, state, version)
OrderLine(orderId, productId, quantity, unitPriceAtOrderTime)

quantity > 0
OrderLine.orderId refers to an existing Order
CapturedPayment(orderId, providerOperationId) unique where appropriate
```

Do not infer money semantics, legal retention, refund model, or cross-tenant rules from this example. Ask or mark them unknown. A foreign key can enforce a row relationship but not an arbitrary distributed business invariant.

## Logical representation alternatives

| Model | Explore when | Failure and maintenance questions |
| --- | --- | --- |
| Normalized relational | Multiple writers, joins, independent lifecycles, strong integrity | Join workload, transaction contention, migrations, over-normalization of rarely separate concepts |
| Controlled denormalization | Measured read patterns need a projection or snapshot | Which value is authoritative? How are duplicates updated and repaired? |
| Document embedding | Bounded, co-read/co-updated subobjects | Growth bounds, independent writers, limits, duplication, update anomalies |
| Document references | High-cardinality/independently updated related objects | Consistency across documents, query costs, explicit relationship checks |
| Key-value / wide-column | Stable known access patterns by key or range | Secondary access patterns, partition skew, item/transaction limits |
| Graph | Traversal/relationship queries dominate | Property updates, operational maturity, need for general transactional queries |
| Dimensional (fact/dimension) | Repeated aggregation and slicing | **Fact grain**, slowly changing dimensions, late facts, measure additivity, ETL lineage |
| Event log + derived views | Audit/event replay is an actual requirement | Event schema versioning, duplicate/out-of-order handling, replays, privacy/deletion, rebuilding views |

Normalization is a way to control functional dependencies and update anomalies, not a universal target such as “always 3NF.” Before denormalizing, name the measured query, acceptable staleness, write amplification and repair procedure. If relationships matter, write an explicit cardinality example and a sample query against both alternatives.

## Data schema checklist for exploration

- Null and missing mean different things? Optional fields and default values have declared semantics.
- Types and units: timestamps/time zones, fixed decimal or integer minor-unit representation for domain money, enumerations and allowed transitions; persisted variants are versioned.
- Uniqueness, check, referential and exclusion constraints have meaningful ownership and expected error mapping.
- Deletes: cascade, restrict, soft deletion, audit trail, retention and restoration chosen for business reasons, not convention.
- Tenant and authorization: direct ID lookup, exports and background jobs do not bypass scope.
- Pagination and sort order: stable tie-breaker, absent/deleted rows, consistency across pages.
- Cross-store derived copies: source-of-truth, lag, reconciliation, backfill and deletion propagation.

## Sources and qualification

- [PostgreSQL table constraints](https://www.postgresql.org/docs/current/ddl-constraints.html): `CHECK` does not safely express arbitrary cross-row checks; use real database facilities for the invariant.
- [MongoDB modeling best practices](https://www.mongodb.com/docs/manual/data-modeling/): embedding/reference choices depend on read/write patterns and cardinality; limits depend on engine/version.
- [Microsoft dimensional modeling guidance](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema): define fact grain and distinguish dimensions from measures in analytical models.

These are documented product/design properties, not proof that a model is correct for the actual application.
