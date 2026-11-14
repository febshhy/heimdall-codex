---
name: graph-protocol
description: Delegate bounded multi-agent work as typed task graphs using A, E, R, with structure at boundaries and comparison on return.
---

# Graph Protocol — canonical orchestration skill

The original ten-section method in `references/PROTOCOL.md` is authoritative. Read it before designing multi-agent work. `references/V3-CONTRACT.md` is only the mechanical representation; it cannot override the original method.

**Scope of graph authority:** A/edges express task flow and named worker outputs; E covers delegation breakpoints; R covers the worker's subgraph, method, verification and WHY. These are *execution/delegation* requirements, not approved product requirements or domain invariants. Take business behavior from `$requirements` and domain/UI/database contracts from their owning methods (`AGENTS.md`). If a worker discovers an unresolved product policy, report it to the coordinator for the requirements Question Gate; do not settle it by rewriting the task graph. Shared words such as "happy path" and "dependency" do not transfer decision authority. Keep the original A/E/R structure unchanged.

**Execution-flow reporting:** Use the shared `AGENTS.md` **Call Graph Output** convention when showing delegation execution flows in a project overview, architecture summary or code explanation: plain-text `ts` fences, hierarchical indented `→` arrows, separate Production and Tests sections if different. A display trace is illustrative only; the required delegated/implemented A/E/R structures and schema-3 comparison remain authoritative.

1. Define nodes, domains, workers, and explicit data-dependency edges (§1).
2. Draw A, choose small single-worker or parallel waves (§2–3).
3. Mark E = wrong context, missing input, misinterpretation (§4).
4. Give each worker R = subgraph, design method, verification argv, WHY (§5).
5. The prompt carries the delegated subgraph; the worker returns the implemented A/E/R graph and named output values (§6, §10).
6. **Trust nothing at the boundary. Trust everything inside.** The worker owns its subgraph until release; never add controller decisions inside (§6, §8).
7. Collect controller observations only before/after work, with shell `scripts/factory begin/end/run` (§7).
8. Compare delegated versus implemented graph and accept only after relevant verification (§9). For independent WRITE work, use a different reviewer and inspect real diff/test evidence.

Use `scripts/factory init`, `prompt`, `begin/end/run`, and `validate`. The controller runs on Linux using Bash+jq; it needs no Python or Go runtime. Schema version 3 is mandatory. For a trivial single-agent task, keep the method but avoid an unnecessary multi-node execution graph.
