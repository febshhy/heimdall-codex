---
name: evidence-research
description: Evidence-based technical investigation for software design choices when important external claims, standards or alternatives need validation; uses independent research/review graph only for broad research.
---

# Evidence research — subordinate investigation

**Authority:** Research supplies evidence to the software factory; it does not approve product policy or replace the main engineering graph. A requested research report may itself be the deliverable.

```text
Small factual question → targeted source → verify fact, version and date → report
Broad consequential research → one node per independent material question
  → independent review of consequential or disputed claims
    → synthesize → coordinator acceptance
      → Accepted evidence | Disputed/unknown | Blocked dependent decision
```

**Broad-graph guards:** give each research agent a bounded question, sources,
and its own scratch artifact. Label important claims
`VERIFIED | UNVERIFIED | DISPUTED` with sources, retrieval dates, and versions.
Assign independent review where a claim could materially change the decision
or is disputed. The coordinator can combine and synthesize findings directly.
Assign separate indexing or synthesis only when volume warrants it. Gate
dependent decisions on the evidence they require.

**Failure transitions:** after a plausible transient failure is corrected, retry at most once, preserving failed records. Missing source, disputed claim or failed review → explicitly report gap and block the decision that depends on it. Nonempty output files are not completion evidence.

**Effects:** scratch under `.work/research/`; durable project `docs/research/` only when specifically authorized and needed for a lasting end-user documentation decision, respecting the protected `docs/` boundary in `AGENTS.md`. Ordinary tasks use a focused lookup, not a three-agent research graph.
