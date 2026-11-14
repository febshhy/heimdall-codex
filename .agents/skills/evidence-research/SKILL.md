---
name: evidence-research
description: Evidence-based technical investigation for software design choices when important external claims, standards or alternatives need validation; uses independent research/review graph only for broad research.
---

# Evidence research — subordinate investigation

**Authority:** Research supplies evidence to the software factory; it does not approve product policy or replace the main engineering graph. A requested research report may itself be the deliverable.

```text
Small factual question → targeted source → verify fact, version and date → report
Broad consequential research → N1, N2, N3… (independent questions)
  → independent reviewer R(Ni) for every Ni
    → single indexer → synthesizer → coordinator acceptance
      → Accepted evidence | Disputed/unknown | Blocked dependent decision
```

**Broad-graph guards:** use at least three non-overlapping research N nodes only when the decision warrants them; give each independent native Codex agent bounded context, its own scratch artifact and sources. Exactly one independent fact-check R node reviews each N. Label important claims `VERIFIED | UNVERIFIED | DISPUTED`, with actual sources, retrieval dates and versions. The indexer alone owns the shared reference inventory. The synthesizer integrates corrected findings, alternatives, unknowns and implementation consequences. The main coordinator confirms every planned N has its R and gates high-risk dependent design on accepted evidence.

**Failure transitions:** after a plausible transient failure is corrected, retry at most once, preserving failed records. Missing source, disputed claim or failed review → explicitly report gap and block the decision that depends on it. Nonempty output files are not completion evidence.

**Effects:** scratch under `.work/research/`; durable project `docs/research/` only when specifically authorized and needed for a lasting end-user documentation decision, respecting the protected `docs/` boundary in `AGENTS.md`. Ordinary tasks use a focused lookup, not a three-agent research graph.
