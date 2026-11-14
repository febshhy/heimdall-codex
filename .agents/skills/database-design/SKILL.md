---
name: database-design
description: Use to explore or review persistent data models, schemas, entity relationships, normalization, database selection, OLTP/OLAP/HTAP workloads, indexes, queries, transactions, storage engines, replication, partitioning, retention, migrations, or data recovery. Compare actual workload and constraints before recommending a technology. Pair with software-design-thinking for domain invariants and effects. Not for unrelated UI styling or tiny code-only edits.
---

# Database design — workload → data contract → evidence

**Authority:** persistence models, constraints, access paths, consistency implementation, durability, recovery and operations. `$software-design-thinking` owns domain facts, shapes, `Inv(S)`, command/effect contracts and resource owners; `$gui-design-thinking` owns view/draft/events. Database `Committed` is not UI `Loading`. This skill cannot invent product rules, force a vendor or override the canonical design methods.

```text
Job + known/unknown facts + readers/writers + failure stakes
  → Representative workload and owned data invariants
    → Logical facts/relationships + constraint boundary
      → Compare existing stack with smallest credible alternatives
        → Critical query access paths + concurrent transaction outcomes
          → Migration, recovery, observability, costs
            → Measured checks and decision | Explicit unknown / experiment
```

**Scale:** a query or column fix needs a relevant shape, compatibility, explain/query check and targeted test. New schema, shared writer, analytics or DB replacement warrants broader evaluation. Use references selectively; no database change/ADR/benchmark for cosmetic UI work.

## Separate the axes

| Axis | Examples | Decision |
| --- | --- | --- |
| Workload | OLTP, OLAP, mixed/HTAP | Operations and service guarantees. |
| Logical model | Relational, document, key-value, graph, dimensional | Identities, relationships, representation. |
| Physical layout | Row/column, B-tree/B+, LSM, log/heap | Storage/write/read behavior of the actual engine. |
| Access | B-tree, hash, inverted, GiST, BRIN, vector/ANN | How specific queries find records. |
| Deployment | Embedded, client/server, managed, replicated | Operations, ownership, failure and recovery. |

Never compare different axes as direct alternatives (for example OLTP vs LSM). An engine may combine them; generic performance rankings do not establish its actual behavior. Use `references/WORKLOAD-AND-CHOICES.md` and `references/STORAGE-ENGINES.md` when selecting an engine.

## Inspect and choose

**Inputs:** known data owners/sensitivity, readers/writers, important point/range/join/aggregate/search/time-series queries, ingest/change streams, observed sizes/rates, skew, hot keys, concurrency, latency/freshness needs, retention, edge/offline needs, regulations, team capability and costs. Unknowns stay unknown. Identify how the current stack works before proposing replacement; do not invent measurements.

**Facts:** keys, identity, cardinality, optionality, temporal meaning, ownership, uniqueness, references, authorization, deletion/retention. Separate authoritative data, projections, drafts, caches and event histories. Compare conceptual entities, logical representation and physical layout. Normalize when it avoids update anomalies; denormalize only with an explicit maintenance/reconciliation rule. Document embedding fits bounded co-updates; independent/high-cardinality records favor references when justified. Analytics requires declared fact grain. Event sources need schema evolution/replay rules. A program type is not automatically a database constraint. For deeper modeling read `references/DATA-MODELING.md`.

**Alternatives:** existing engine first; compare at least one simpler baseline when a real choice exists. Evaluate transactions/isolation, access, security, workload fit, recovery, migrations, team experience, observability, license/hosting, portability and reversal cost. Secondary search/analytics systems add synchronization, reindex and failure modes; evaluate costs explicitly. Distinguish verified engine/version properties from vendor assertions. For B+/LSM choices inspect compaction, caching, media and real write pattern rather than assuming speed.

**Access and concurrency:** for critical queries record predicates, ordering, cardinality, projection, pagination, selectivity and actual plans; consider index order, expression/partial/covering variants and write/storage costs (`references/QUERY-AND-INDEX-DESIGN.md`). For multiple writers define transaction boundary, constraints, isolation, conflict resolution, duplicate/retry and idempotency behavior. Locks, optimistic versions, serializable transactions and single-writer queues are different; test selected engine semantics. A timed-out write may have **unknown outcome**. Use `../software-design-thinking/references/CONCURRENCY.md` and `EFFECTS-AND-RECOVERY.md` when relevant.

**Operations:** plan schema versions and readers, backfills, data moves, retention, deletion, backup/restore exercises, recovery point/time objectives, encryption/access, auditability, replication/partition failures and derived-view lag/rebuild/reconciliation. Replicas are not backups. Use expand/migrate/contract only where live compatibility is actually needed; see `references/OPERATIONS-AND-EVOLUTION.md`.

## Decision and verification

```text
Evidence = (inspected schema/migration revision, actual query plans,
            measured or explicitly unknown rates, conflict/retry tests,
            backup/restore exercise when material, accepted requirements)

Claim accepted ⇒ relevant evidence addresses its scope
```

Test constraint violations, conflicting writers, 0/1/large/skewed data, plan regressions, crash/retry and restoration as appropriate. Do not claim a product or schema is validated from this guide alone. Output a bounded decision sketch: workload, data facts/invariants/owners, knowns/unknowns, existing-stack baseline and credible alternatives, keys/constraints/queries, transaction/effect/recovery contract, operational costs, evidence, next experiment/owner. ADR only for consequential hard-to-reverse choice.

**Audit boundary:** show current-source-derived, revision-labeled ERD/data slice only for material relationships, cardinality, ownership or migration decisions. Proposed logical models and implemented schema must be labeled separately; diagrams do not override actual constraints. Small changes need only focused schema diff/check. Refresh or mark stale after source changes. Graph Protocol governs delegation only, not database topology; keep `docs/` protected under `AGENTS.md`.
