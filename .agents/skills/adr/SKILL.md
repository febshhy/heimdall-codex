---
name: adr
description: Use for an important architectural decision that is difficult to reverse. Skip routine features, fixes, refactors, and naming decisions.
---

# ADR — consequential, hard-to-reverse choice

**Trigger:** an important architectural one-way door. Skip routine features, fixes, names, and reversible refactors.

```text
Consequential choice?
  → No: no ADR
  → Yes: read applicable decisions and project criteria
    → Existing ADR? supersede instead of duplicate
      → Draft Proposed(Context, Evidence, Alternatives, Decision,
                       Consequences, Revisit condition)
        → Human review → Accepted | Remain Proposed
```

**Authority:** only a person may mark an ADR `Accepted`; an ADR cannot override an approved requirement. A conflict returns to the requirements Question Gate.

**Guards and output:** read project `docs/adr/README.md` when present; otherwise use `assets/ADR_TEMPLATE.md` and these criteria. Read existing relevant ADRs; keep facts source-grounded and decision concise (one or two sentences), with real alternatives and reversal/review condition. Create at most one new ADR per task. If the project explicitly adopts `docs/adr/`, propose the next number and write only with approval under the project's protected `docs/` rule; otherwise use its existing decision-record location, without overwriting. Report path and `Proposed` status. Do not turn an inferred historical choice into an accepted ADR.
