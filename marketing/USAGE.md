# Use Heimdall on a real task

**Tell Codex the outcome you need; Heimdall supplies the engineering procedure.** You do not need to choose a skill, design a task graph, or request extra agents for routine work.

[Overview](../README.md) · [Install Heimdall](SETUP.md) · [Understand the method](HOW_IT_WORKS.md)

## First session

From an installed project root, start Codex:

```bash
codex
```

For an existing project, start with evidence before changes:

> Inspect this repository's instructions, source, and tests. Explain its relevant behavior and trace one important production path with actual source names. Identify unknowns and available checks. Recommend one bounded improvement. Do not edit files yet.

For a new project, start with the desired behavior:

> Help me define the first useful feature. Identify the user outcome, happy and unhappy paths, constraints, and acceptance checks. Recommend a small design using my chosen stack. Ask about decisions that materially affect behavior. Do not create files yet.

Review the proposal. Then ask Codex to implement the agreed scope and report the tests it actually ran.

## Task examples

Replace text in square brackets with your own context. These prompts are starting points; adapt them to the application's real requirements.

### Fix a bug

> Reproduce [problem], trace its relevant callers and state, and implement the smallest justified fix. Run focused tests. Report pass, fail, and unverified outcomes.

### Change shared behavior

> Implement [feature]. Inspect every relevant reader and writer of the affected contract. Define allowed and denied cases, update the approved paths, and verify those cases.

### Improve code structure

> Make [module] easier to change while preserving its behavior. Decide whether tidying should come first, after, later, or not at all. Keep structural changes reviewable and state the limits of equivalence checks.

### Build or revise a UI

> Improve [screen or flow]. Trace real loading, empty, error, and success states. Preserve focus, keyboard support, meaningful copy, and reduced-motion behavior. Use the existing platform and design system; verify the available states.

### Review data access or migration

> Evaluate [query, schema, or migration]. Identify ownership, invariants, workload, failure and recovery paths. Compare the smallest practical options. Do not execute destructive changes without approval.

### Write product copy

> Rewrite [surface] for [audience and locale]. Preserve actual product behavior and terminology. Make the next action clear, check factual claims, and apply plain-language and RASA review.

### Coordinate a larger change

> Implement [feature] across [components]. Agree on the shared contract first. Delegate only tasks with clear boundaries and prerequisites. Review integration and report actual verification evidence.

### Specify a formal rule

> For [critical rule], draft candidate Bend laws from approved intent and identify assumptions and counterexamples. Request review of the exact laws before treating them as binding. Keep proof and production conformance separate.

## Decide whether the result is ready

Before accepting a change, look for:

- the intended behavior and actual files changed;
- checks run, observed outcomes, and the claims each check supports;
- failed or skipped checks, unresolved decisions, and remaining risks.

Inspect the working diff when relevant:

```bash
git status --short
git diff --stat
git diff --check
```

A passing check does not establish correctness outside its tested scope. Heimdall does not replace your team's deployment and review controls.

**[Install or recover Heimdall](SETUP.md)** · [Understand the evidence model](HOW_IT_WORKS.md#what-counts-as-evidence)
