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
    → Existing ADR? link a proposed successor
      → Draft Proposed(Context, Evidence, Alternatives, Decision,
                       Consequences, Revisit condition)
        → Human review → Accepted | Remain Proposed
```

**Authority:** only a person may mark an ADR `Accepted`; an ADR cannot override an approved requirement. A conflict returns to the requirements Question Gate.

**Guards and output:** read project `docs/adr/README.md` when present; otherwise use `assets/ADR_TEMPLATE.md` and these criteria. Read relevant ADRs and keep facts source-grounded. Record one ADR per consequential decision that can be accepted or reversed independently. A proposed successor leaves the existing ADR in force until acceptance. Include real alternatives and a revisit condition. Use the existing decision-record location. Obtain explicit authorization for writes to protected `docs/`. Report the path and status. Historical source structure alone cannot establish an accepted ADR.
