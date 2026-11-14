# Operations and evolution — a schema lives beyond its first migration

## Evolving a persisted contract

1. **Inspect real consumers:** code, reports, exports, jobs, mobile/offline clients, integrations, old app versions and downstream warehouse pipelines.
2. **Classify compatibility:** brand-new greenfield schema vs existing live data/consumers. For live systems, an expand → backfill/migrate → contract sequence may reduce risk; it is not automatically needed in an empty new installation.
3. **Plan safety:** data validation before new constraints, large backfill batching, retries, online/offline migration window, dual-read/write risks, migration pause/resume, data correctness comparisons.
4. **Recovery:** roll back when the step is genuinely reversible; otherwise retain a tested *forward recovery* path. Destructive deletion or information loss cannot be undone merely by reversing DDL.
5. **Ownership:** identify who approves irreversible deletes, who can restore data, which external consumers must be notified, and what evidence closes the change.

## Durability and recovery questions

| Concern | Ask | Validate |
| --- | --- | --- |
| Backup | What is included: base data, WAL/log, keys, metadata, offsite copies? | Restore into isolated environment with application read/query checks |
| RPO / RTO | How much data loss and downtime is acceptable? | Observed drill, not a vendor default |
| Replication | What does lag/failover/fencing look like? | Kill/partition tests where feasible; prevent split-brain/duplicate effects |
| Retention | What legal/business deletion windows exist? | TTL/partition drop, delayed copies, caches, backups and exports addressed |
| Security | Who can read/write/restore/decrypt? | Least privilege, secrets handling, tenant isolation, auditing as needed |
| Recovery | Can operator reconstruct the last authoritative state and pending effects? | Exercise interrupted migration, double submit, timeout, restore/replay |
| Maintenance | When do vacuum, compaction, rebuild, checkpoints, statistics or index changes run? | Monitor amplification, IO, backlog, lock duration, disk exhaustion |
| Derived stores | How are analytics, cache and search kept consistent and rebuildable? | Lag, reconciliation, reprocessing, delete propagation, stale-state presentation |

A replica is not a backup against accidental deletion or corruption propagated to replicas. “Highly available” is not synonymous with a tested disaster recovery plan. Encrypting data does not authorize queries; enforce tenant/access scopes explicitly.

## Engine selection and long-term cost

Estimate development, migrations, hosting, monitoring/on-call, upgrade windows, restore drills, expertise, compliance, vendor egress and retirement. A new distributed database introduces coordination, failure domains and incident response procedures; quantify the demonstrated benefit. Prefer incremental reversible steps where they meet requirements, but state real irreversible boundaries.

## GUI and event handoff

If an operation times out after database commit, the UI must not label it failed if the outcome is unknown. Use a stable operation ID, status lookup/reconciliation, bounded retry, and explicit progress/error/offline states as described by [GUI Design Thinking](../../gui-design-thinking/SKILL.md) and [Effects and recovery](../../software-design-thinking/references/EFFECTS-AND-RECOVERY.md). Keep GUI draft, domain transition and durable database state distinct.

## Primary sources

- [PostgreSQL backup and restore](https://www.postgresql.org/docs/current/backup.html)
- [PostgreSQL transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [SQLite backup API](https://www.sqlite.org/backup.html)
- [DynamoDB partition key workload skew](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-uniform-load.html)
