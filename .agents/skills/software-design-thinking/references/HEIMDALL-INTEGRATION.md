# Heimdall integration — project-specific extensions

The authoritative software method is `../SKILL.md`, supplied by the project owner. This reference carries additional Heimdall procedures previously mixed into the method. Apply each only when the trigger fits. Do not replace or abbreviate the original 15 sections and pipeline.

## Requirements, artifact and design depth

- Link applicable requirement IDs from `$requirements` and any accepted ADRs. For requirements or decisions not yet resolved, mark Known / Unknown / Assumption / Decision; never invent identifiers.
- Treat approved product behavior as an input to domain design, not as a policy the domain method may amend. Derive invariants, commands and effects that implement that behavior; if an invariant implies a new business rule or contradicts the approved contract, return the question to `$requirements` before committing to the affected design. Do not convert an implementation preference into a requirement.
- Dependency vocabulary is shared but authority is not: the domain method owns logical/resource dependencies, `$database-design` owns their persisted implementation, and `$graph-protocol` owns worker/task dependencies. Its `R` is a worker prompt completeness check, not a product requirement. See `AGENTS.md` for the authority map.
- Preserve the original one-page artifact: shapes, invariants, graph, errors, needs, owners. A module-level `AGENTS.md` under `## Design` may also be required by Heimdall for substantial module changes; it is a *project recording format*, not a replacement for the method. If a brief module card cannot contain the explanation, link to the detailed design. A 60-line card limit is a review heuristic, not a reason to delete important constraints.
- A module card may record `Requirements`, `Depth`, `Language`, `Depends on`, `Volatility`, `Shapes`, `Invariants`, `Flow`, `Errors`, `Needs/Owners`, `Claims`. Do not force absent categories into fabricated content. `Depth: small` can be shorter.
- `Depends on: X -> conform` means the module adopts X's contract; `translate` means it maps X at a real boundary. Give each shared shape an owner. Treat volatile dependencies with care.

## Change boundaries and coupling

- Prefer a deep module: modest public interface, meaningful hidden behavior, stable contract. A single implementation may still merit an interface when the boundary itself is real. Delete pass-through wrappers that add no contract or responsibility.
- Audit duplicated rules, repeated parameter groups, scattered small changes, misplaced owners, hubs and dependencies on volatile modules. A high fan-in module can be legitimate when stable and narrow.
- Classify consequential decisions by reversal cost. For difficult-to-reverse data, public contracts, or destructive operations, record an ADR and a migration/rollback strategy; use `$software-factory` critical handling when applicable.
- When updating persisted data or public interfaces, prefer staged expand → migrate → contract with explicit compatibility windows, measurement and rollback/recovery plans where feasible. Do not presume all changes can be reversed after data loss.

## Evaluate consequential structure decisions

Use this evaluation only when a structural choice materially affects dependencies,
contracts, testability, future changes, or reversal cost; do not create a design
exercise for routine local edits.

- Name the concrete current requirement and credible change scenarios. Distinguish
  observed change pressure from speculation; optimize for the current need unless
  a future change has sufficient evidence or impact.
- Compare the existing/simple design with the smallest useful alternative. Inspect
  which responsibilities change together, coupling across ownership boundaries,
  cohesion, and whether a dependency belongs to a stable contract.
- Introduce an interface or indirection for a real behavioral, ownership, security,
  failure, or independently replaceable boundary. Multiple implementations are not
  a prerequisite, and anticipated reuse alone is not enough.
- Check whether a proposed abstraction preserves substitutability: inputs,
  outputs, errors, ordering, effects, resource ownership, and other applicable
  observable promises. Evaluate verification cost, operational complexity,
  maintenance, migration, and reversibility alongside implementation effort.
- Prefer the smallest justified solution. Record material alternatives and their
  tradeoffs in the existing design artifact or an ADR only when the ADR trigger
  applies; never invent historical rationale. Keep the 15-section design method
  and its language-agnostic graph authoritative.

## Premortem, security and compatibility

- For a full/risky design, name likely production failures and map each to an invariant, error strategy, verification check, or accepted risk.
- At real trust boundaries, examine spoofing, tampering, repudiation, disclosure, denial/exhaustion and privilege escalation where applicable. Record durable findings in project-owned `docs/security/` if it exists.
- Public APIs can have undocumented consumers. Inspect usage, versioning, error behavior, ordering and timing before changing an observable contract. Never silently change another owner's model.

## Verification and optional formal proof

- Link claims to appropriate checks through `$testing`. Property-based/generated-sequence tests are valid for ordinary state machines, parsers and invariants **without Bend**. Use types, behavioral/conformance/regression tests, or real boundary checks as fit; avoid redundant cases.
- If Bend is explicitly enabled and a particular pure invariant is selected for proof, follow `$bend-proof` proof-first order and conformance tests against production. Formal proof of a model does not prove production implementation; ordinary tests do not prove every execution.
- Prototype thin end-to-end slices early where safe; preserve proof-first order only for selected formal models. Update the graph before changing code when a new fact changes the design.

## Call graph presentation

For project overviews, architecture summaries, code explanations and displayed execution traces, follow `AGENTS.md` **Call Graph Output**: a plain-text `ts` block with indented `→` steps, plus separate Production and Tests sections when they differ. Derive call paths from actual code and tests or mark them proposed/unknown. This format is only the visible projection of the canonical graph: still model shapes, invariants, state, error branches, effects, needs and owners in `../SKILL.md`. If the code differs from that graph, correct the design and implementation; formatting does not establish correctness.

## Separation from GUI

`$software-design-thinking` owns domain commands, invariants, and program effects. `$gui-design-thinking` owns surfaces, human moves, view/navigation state, focus and UI effects. Map a UI event to a domain command through an explicit boundary, and map the typed outcome back to a UI event. Do not conflate `Submitting` (UI) with `Paid` (domain). `$visual-design` presents the GUI contract without modifying its transitions.
