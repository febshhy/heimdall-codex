---
name: project-adoption
description: >-
  Use after Heimdall is installed in an existing project to establish a reviewable,
  language-agnostic architecture baseline. Inspect the actual code and its
  existing architecture records; follow software-design-thinking's call graph
  output contract. Never infer historical decisions without evidence.
---

# Project adoption — source-grounded engineering investigation

**Trigger:** after a verified Heimdall installation in an existing repository. This is an agent investigation, not an installation prerequisite, parser coverage gate, or permission to refactor.

```text
Inspect project instructions + requirements + ADRs + tests
  → Choose relevant subsystem and inspected revision
    → Follow actual entry points and boundaries (language-agnostic)
      → Source-grounded call-graph slice + Software Design Thinking model
        → Compare with accepted records
          → Known | Unknown | Assumption | Proposed Decision
            → User review → Accepted baseline | Partial findings
```

**Authority:** `$requirements` owns approved behavior, `$software-design-thinking` owns state/shapes/invariants/errors/needs/effects/owners, `$testing` owns verification, `$adr` owns consequential proposed decisions, `$repository-work` owns authorized writes. Load only applicable skills.

**Call graph:** follow the installed `.heimdall/AGENTS.md` Call Graph Output format: plain-text `ts` fence, actual names and hierarchical `→` edges. Separate Production and Tests only when wiring differs. Mark unsupported edges `unknown` or `proposed`. A source-inspected graph is not runtime observation; investigate cross-language, package, process and external boundaries without requiring any language-specific scanner. Scope to a relevant path, not all symbols.

**Evidence and output:** one compact Software Design Thinking slice per bounded flow: shapes, state, invariant, graph, errors, needs/effects, owners; cite inspected paths/revision, tests/deployment limits, conflicts and unresolved approvals. Source shape alone does not prove historical ADR rationale. Do not generate automatic historical `ADR-0000` records; proposed new ADRs remain Proposed until a person accepts. Start with one high-impact subsystem for large repos; report partial discovery without blocking installation.

**Effects and security:** read existing `docs/` only when allowed; never create/change/delete protected end-user project docs automatically. Save an artifact only upon explicit approval of that documentation effect. Keep preliminary findings in the response. Do not execute untrusted code or inspect credential values as automatic discovery, fabricate entry points, edges, test coverage, approval or data; do not enlarge Codex permissions.
