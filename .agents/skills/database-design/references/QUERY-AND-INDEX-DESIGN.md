# Query and index design — measure the access path

## Query inventory

Record each important query in its real parameterized form: filtering, join keys, sorting, top-K/limit, authorization predicates, output columns, skew and expected cardinalities. Use stable ordering for pagination; clarify whether snapshot consistency across pages is required. Queries must scope tenant/auth permissions at the authoritative boundary.

## Index exploration

- **No index / scan:** useful for small tables or when a large share of data must be visited; do not reject a sequential scan automatically.
- **Sorted B-tree:** equality, range and ordering, with leading columns and predicate/selectivity interactions. Composite index order must follow actual workload, not a rigid universal rule.
- **Partial or expression indexes:** smaller targeted access patterns, but predicates and function expressions must match engine/planner capabilities.
- **Covering/index-only:** can reduce table visits under the relevant visibility/data conditions; storage and write amplification rise.
- **Full-text/inverted, spatial, BRIN, vector:** only for actual search/geometry/locality/ANN requirements. Approximate vector results require recall evaluation, not just latency.
- **Partition pruning:** can reduce scanned data when keys and predicates align; partitioning by itself does not fix every slow query and adds metadata/operational overhead.

Additional indexes cost space, vacuum/maintenance, writes and migrations. Check selectivity and skew and retain a hypothesis about the missing/poor access path before adding one.

## Evidence and limitations

Use a real execution plan and, where safe, plan *execution* to compare expected and actual cardinalities. In PostgreSQL, `EXPLAIN ANALYZE` executes the statement; running it for a data-modifying statement has effects unless appropriately contained. Planning/execution times do not include every application/network component. A 100-row plan is not representative of a 10-million-row plan.

Compare before/after at representative sizes, query mix, parameters, cache state and concurrent writes. Capture actual latency, I/O, index size, query plan, row count estimates and lock waits where relevant. If the product is not installed or real data unavailable, say **not measured**.

## Verification prompts

- What happens at 0 rows, one row, very large cardinality, a highly popular key, or a large IN list?
- Does row-level or tenant authorization remain enforced by direct fetch, export, batch and background jobs?
- Is pagination deterministic? Are repeated/deleted rows handled?
- Does the index still help when parameters change, statistics age, or data becomes skewed?
- Does the transaction choose an appropriate isolation level for the invariant under concurrency?

## Sources

- [PostgreSQL EXPLAIN and its measurement caveats](https://www.postgresql.org/docs/current/using-explain.html)
- [PostgreSQL indexes and overhead](https://www.postgresql.org/docs/current/indexes.html)
- [PostgreSQL multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html)
