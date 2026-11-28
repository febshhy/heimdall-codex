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
    → Existing ADR? inspect it as applicable
      → After evidence, optionally record rationale in ignored `.work/`
        only when useful; task notes are never planned or committed
        → Human review of any durable project decision record, if separately authorized
```

**Authority:** only a person may mark an ADR `Accepted`; an ADR cannot override an approved requirement. A conflict returns to the requirements Question Gate.

**Guards and output:** read project `docs/adr/README.md` when present; otherwise use `assets/ADR_TEMPLATE.md` and these criteria. Read relevant ADRs and keep facts source-grounded. For a consequential decision, keep rationale, alternatives, and revisit conditions evidence-grounded. Task-specific ADR rationale is never a planned deliverable and may be recorded only after evidence, only when useful, and only in ignored `.work/`; never commit it or put task notes in `docs/`. Durable project decision records may be changed only under a separate explicit authorization and remain subject to human acceptance. Obtain explicit authorization for protected `docs/` writes. Task security findings follow the same ephemeral-only rule; this does not alter actual project security guidance. Report the path and status of any note actually created. Historical source structure alone cannot establish an accepted ADR.
