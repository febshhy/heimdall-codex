# How Heimdall works

**Heimdall connects the request, the affected code, the change, and its verification.** That connection helps you review the reasoning before approving work and inspect the evidence afterward.

[Overview](../README.md) · [Install](SETUP.md) · [Use it on a task](USAGE.md)

## The method

A change can cross more boundaries than the first file suggests. Heimdall directs Codex to investigate the actual repository before choosing an implementation.

| Stage | Decision or work | Evidence you can inspect |
| --- | --- | --- |
| **Understand** | Establish the required outcome, constraints, failure cases, and unresolved decisions. | Approved behavior and explicit unknowns. |
| **Trace** | Follow relevant source paths, callers, state, side effects, and tests. | Source-grounded call graph and affected boundaries. |
| **Choose** | Compare the smallest feasible change with credible alternatives. | Design choices, costs, and a verification plan. |
| **Change** | Implement only the approved scope. Separate structural work where helpful. | Focused source diff. |
| **Verify** | Run relevant checks and review their actual outcomes. | Passing, failing, blocked, and unrun checks. |

A single agent can handle bounded work. When several tasks have real dependencies, Heimdall's Graph Protocol defines ownership and handoffs. Its optional factory controller checks recorded task contracts and local observations; it does not launch agents or independently establish application correctness.

## Example: a shared access rule

**Request:** Allow team members to view only the reports they are authorized to access.

Hiding reports in the interface may leave direct API calls, exports, or scheduled delivery unchanged. The question is which real paths expose reports and where authorization must hold.

Codex should trace the paths present in the source, then test the relevant allowed and denied cases. A bounded investigation might produce:

```text
Possible paths — confirm against source:
Report request
  → API authorization boundary
    → report lookup
Export request
  → export authorization boundary
Scheduled delivery
  → recipient eligibility check
```

The example is hypothetical. Its paths are not evidence about your application. Final call graphs must use inspected source names and explicitly mark any missing or inferred edge.

A useful outcome is a focused change with evidence for each affected access path—not an unsupported promise that the system is secure.

## What counts as evidence?

| Claim | Appropriate support | What it does not establish |
| --- | --- | --- |
| A source path exists | Inspected source at a known revision | That the path ran in production. |
| A behavior passed a test | Actual command, result, and covered case | Correctness of all untested paths. |
| A delegated task met its contract | Recorded handoff plus observed Git/command evidence | An independent security attestation. |
| A Bend law was proved | Reviewed law, proof result, and model assumptions | Conformance of separate production code. |

Heimdall keeps these categories distinct. The main Codex agent plans and integrates work; product owners approve consequential behavior; project tests and human review supply acceptance evidence. Deployment and access control remain under your environment's controls.

## Where the same method applies

The skills cover software design, GUI state, data modeling, testing, research, architectural decisions, and clear product writing. The [engineering playbook](ENGINEERING_PLAYBOOK.md) teaches the underlying patterns with an end-to-end example. Optional Bend 2 laws can specify selected formal behavior; [the proof guide](../proofs/README.md) explains the separate proof and production checks.

**[Start with setup](SETUP.md)** · [Choose a task](USAGE.md#task-examples) · [Back to Heimdall](../README.md)
