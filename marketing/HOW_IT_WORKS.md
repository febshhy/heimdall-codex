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

A single agent can handle bounded work. When several tasks have real dependencies, Heimdall's Graph Protocol defines ownership and handoffs. The optional factory controller checks recorded task contracts and local observations.

## Example: a shared access rule

**Request:** Allow team members to view only the reports they are authorized to access.

Trace report access through the interface, API, exports, and scheduled delivery. Locate the authorization check for each path.

Test allowed and denied cases on each affected path. An example call graph:

```text
Report request
  → API authorization boundary
    → report lookup
Export request
  → export authorization boundary
Scheduled delivery
  → recipient eligibility check
```

## What counts as evidence?

| Claim | Evidence |
| --- | --- |
| A source path exists | Inspected source at a known revision. |
| A behavior passed a test | Actual command, result, and covered case. |
| A delegated task met its contract | Recorded handoff and observed Git and command results. |
| A Bend law was proved | Reviewed law, proof result, and model assumptions. |
| Production code conforms to a proved law | Conformance checks against the implementation. |

The main Codex agent plans and integrates work. Product owners approve consequential behavior. Project tests and independent review supply acceptance evidence.

## Where the same method applies

The skills cover software design, GUI state, data modeling, testing, research, architectural decisions, and clear product writing. The [engineering playbook](ENGINEERING_PLAYBOOK.md) teaches the underlying patterns with an end-to-end example. Optional Bend 2 laws can specify selected formal behavior; [the proof guide](../proofs/README.md) explains the separate proof and production checks.

**[Start with setup](SETUP.md)** · [Choose a task](USAGE.md#task-examples) · [Back to Heimdall](../README.md)
