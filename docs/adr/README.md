# Architecture decision records

ADRs explain **why** an important technical choice was made. A new project has no accepted ADRs until an authorized decision-maker accepts one.

Create an ADR when a choice has long-lived consequences, establishes an architectural boundary, changes a data contract, affects security or operations, or is costly to reverse. Routine fixes and local refactors usually do not need one.

## Record a decision

1. Copy [the ADR template](ADR_TEMPLATE.md) to `NNNN-short-title.md` using the next unused number.
2. Describe the real constraint, alternatives, consequences, and reversal trigger.
3. Mark it `Proposed` until an authorized decision-maker accepts it.
4. Keep accepted records; when the decision changes, create another ADR and mark the old one `Superseded by ADR-NNNN`.

## Status meanings

| Status | Meaning |
| --- | --- |
| Proposed | Under consideration; not an implementation authority |
| Accepted | Approved by an authorized decision-maker |
| Rejected | Considered and declined |
| Superseded by ADR-NNNN | Replaced by a later decision |

An accepted ADR does not override approved product requirements or verified security constraints.
