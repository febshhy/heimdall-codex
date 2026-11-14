# Storage and access structures — think in tradeoffs

Storage-engine families are *not* workload categories or complete database products. A B-tree/B+ tree may be an index in a row-oriented database; an LSM tree may be part of an embedded engine or distributed service. Many systems mix multiple methods. Compare the specific product/version and settings before expecting a performance behavior.

## B-tree / B+ tree family

Sorted page-based trees support ordered keys, equality and range access; B+ variants generally store leaf-level entries and can support ordered scans. Cache locality, page splits, page/record width, fillfactor, concurrency and storage medium affect actual performance. “B-tree” in product documentation may describe a B+ family variant; do not infer internals from the label alone.

**Explore for:** selective equality and range filters, ordered retrieval and stable predictable access paths. **Inspect:** write amplification and fragmentation under random writes, cache misses, index size, page maintenance and MVCC/storage architecture. A database's clustered/nonclustered choices are product-specific.

## LSM (log-structured merge) family

Often buffers incoming writes in memory, flushes sorted runs to storage and merges runs through compaction. Bloom filters, caching and level layout can limit reads but do not eliminate all read/space overhead. **Compaction strategy is part of the workload contract**: leveled, tiered/universal and FIFO policies have different write/read/space amplification profiles. Bursty ingest may later compete with reads during compaction.

**Explore for:** sustained write/ingest and key/range workloads where this tradeoff is beneficial. **Inspect:** write stalls, L0 pressure, compaction CPU/I/O/space, tombstones, read amplification, cache and failure recovery. Do not claim “LSM is always faster for writes” or that every NoSQL store uses LSM.

## Row layout vs column layout

Row-oriented storage often suits retrieving/updating complete operational records; column-oriented storage can reduce I/O and compress repeated values for scans of selected columns. Real engines have hybrid formats, index/column stores, vectorized execution and different mutation paths. **Do not confuse a columnar layout with a column-family or wide-column logical model.**

## Other structures and their uses

| Access structure | Relevant query shape | Known question |
| --- | --- | --- |
| Hash | Exact key equality | Range and order support? Collision, memory, persistence? |
| Inverted / GIN-like | Membership, full text, arrays/doc terms | Tokenization, update cost, false matches/rechecks? |
| GiST / R-tree family | Spatial or custom predicates | Operator semantics, false positives, rebuild/maintenance? |
| BRIN/zone maps | Physical locality and block-range summaries | Data correlation with storage order, lossy rechecks? |
| Bitmap / column indexes | Batch predicates, aggregation | Writes and high-cardinality overhead? |
| Vector ANN (HNSW, IVF variants) | Approximate neighbor retrieval | Recall, filtering accuracy, rebuild/memory cost, staleness? |
| Append-only log | Sequential persistence/events | Random lookups, retention, compaction and replay semantics? |

Indexes and persistence layouts are distinct. PostgreSQL's B-tree, GIN and BRIN are examples of index methods; RocksDB's LSM compaction is a storage-engine mechanism. Do not select a new database merely to get a different index type when the existing engine already supports the required query.

## Example controlled comparison

Define a representative mix (e.g., random point reads, time-range scans, burst writes, deletes, and a hot tenant), then compare index sizes, p95/p99 latency, compaction interference, storage/write amplification, recovery after restart and maintenance cost on the *same* hardware and data. Document workload skew and engine settings; do not extrapolate from a single synthetic key distribution.

## Primary sources

- [PostgreSQL index methods](https://www.postgresql.org/docs/current/indexes-types.html)
- [PostgreSQL multicolumn index behavior](https://www.postgresql.org/docs/current/indexes-multicolumn.html)
- [RocksDB compaction policies](https://github.com/facebook/rocksdb/wiki/Compaction) (project-maintained wiki; confirm current implementation/settings)
- [SQLite WAL](https://sqlite.org/wal.html)
