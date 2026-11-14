# Workloads and database candidates

Use for an actual database choice or material architecture change. Treat names as candidates, not a technology ranking. Inspect deployed engine/version and current team expertise. The first candidate is the existing database when it already works.

## Capture the workload

```text
Operation | access pattern | read/write rate | cardinality and skew
latency budget / freshness | transaction boundary | growth / retention
failure budget | security / residency | current observed evidence
```

Include normal and degraded conditions, batch jobs, single/hot keys, 0/1/very-large cardinality, peak concurrency, tail latency and access from offline clients. Where figures are unknown, record the uncertainty and design a bounded representative measurement. Estimate independently of vendor marketing.

## Workload versus implementation

- **OLTP:** primarily short, selective operational transactions and invariant-preserving writes. Indexes, conflicts, availability and predictable tail latency matter.
- **OLAP:** scans, grouping, aggregations and complex analytical transformations over large sets. Columnar compression/execution and dimensional models can help, but actual requirements decide.
- **HTAP / mixed:** transactional freshness plus analytics over related or shared data; evaluate one system with mixed-workload isolation versus a maintained analytical copy and its lag.
- **Real-time search / vector / graph / time series:** query semantics and recall, traversals or event/time-window access may justify a specialized engine. A separate index or cache adds synchronization, authorization, rebuild and consistency work.

OLTP/OLAP/HTAP describe **workloads**. Relational/document/graph describe **models**. Row/column and LSM/B+ tree describe **physical choices**. Embedded/server/distributed describe **deployments**. A product may span more than one category.

## Candidate selection matrix

| Candidate | Typical reasons to evaluate | Key conditions to investigate |
| --- | --- | --- |
| SQLite embedded | Local, edge, mobile, single-host service, low maintenance | One writer at a time per database file; WAL reader/writer coexistence and checkpoints; avoid direct multi-host shared-file access |
| PostgreSQL / established server SQL | Shared OLTP, joins, constraints, transactions, mixed SQL | Server operations, isolation, extensions, query plans, connection pressure, backup/restore, write cost |
| MySQL / another existing RDBMS | Existing operational knowledge and workloads satisfied | Exact engine/version isolation, replication behavior, constraints, migrations and plan evidence |
| Document store | Independently evolving document-shaped aggregates, flexible nested data | Embed vs reference, bounded object sizes, independent writes, query/index cost, transactions and migration |
| Key-value / wide-column | Predictable key/range access and scalable ingest | Hot partition keys, secondary query needs, transaction model, compaction and operational burden |
| Columnar warehouse/analytics | Scans, aggregates and compression at analytic scale | Ingest freshness, update/delete cost, OLTP fit, warehouse cost, data movement, latency |
| Search / vector index | Relevance, text, approximate nearest-neighbor retrieval | Recall/latency tradeoff, rebuild, filtering and authorization, consistency with truth store |
| Graph database | Relationship traversal is central and measured | Transaction and query fit, traversal depth, operational knowledge, data consistency |
| Time-series optimized engine | High-volume time-based ingest and range/rollup | Retention, high-cardinality dimensions, late arrivals, compression, source/replica consistency |
| Distributed transactional store | Strong consistency across failure domains with proven need | Consensus costs, latency, topology, operations, network partitions, vendor dependence and recoverability |

Avoid false binaries. PostgreSQL may be enough for moderate reporting, full-text, JSON, time-series patterns, or extension-based search. SQLite can support some server applications behind an application API; it is not automatically restricted to mobile apps. Engine internals must be checked *per implementation*.

## Selection experiment

Choose two or three *plausible* candidates and a simple existing-stack baseline. For each, run the **same representative data size, skew, queries, concurrency and failure tests**, documenting hardware/configuration and costs. Measure end-to-end latency, throughput, tail behavior, correctness, operational steps, recovery and migration burden. If deployment or benchmark is unavailable, mark results as predictions rather than observations. Stop when a candidate satisfies the requirements with understood risk; do not add a specialized system for prestige.

## Primary documentation

- [SQLite appropriate uses and one-writer semantics](https://www.sqlite.org/whentouse.html)
- [SQLite WAL and single-host limitations](https://sqlite.org/wal.html)
- [PostgreSQL indexes](https://www.postgresql.org/docs/current/indexes.html)
- [MongoDB document data modeling](https://www.mongodb.com/docs/manual/data-modeling/)
- [Microsoft fact/dimension star-schema guidance](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema)
- [DynamoDB partition key balance](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-uniform-load.html)

These are product-specific examples. Verify versions, availability, pricing and operational claims before choosing a product.
