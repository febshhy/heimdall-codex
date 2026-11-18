# Use Heimdall on a real task

**Tell Codex the outcome you need. Heimdall supplies the engineering procedure.**

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

Replace text in square brackets with your own context. Adapt each prompt to your application’s requirements.

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

### Independently review delegated changes

Use an independent reviewer for delegated WRITE work. In CLI, IDE, and desktop Local or Worktree sessions, set the session that launches the reviewer to read-only. Reviewer permissions come from that session.

1. Wait for the delegated WRITE work and any running shell commands to finish, then inspect the integrated diff.
2. Set the active session to read-only:
   - In Codex CLI, enter `/permissions` and press Enter to open the permissions picker. Select the **Read-only** profile and confirm that it is active before continuing.
   - In the Codex IDE extension, open the permissions control below the composer and select the **Read-only** profile. Confirm that it is active before continuing.
   - In the ChatGPT desktop app's Codex view, open the permissions control below the composer and select a profile that is configured as read-only. If you use **Custom (config.toml)**, verify that its effective profile is `:read-only`.
3. Ask Codex to start `heimdall_reviewer` (or a separate `default` agent if it is unavailable) to inspect the final diff, relevant requirements, source, and tests. Tell it not to edit files and to report concrete findings and checks observed.
4. Keep the session in read-only mode during review. If Codex requests approval for a write or command that could change files, deny it; report that check as unverified if it cannot be completed read-only.
5. Inspect the review result. If changes are needed, restore the prior profile using the same CLI command or permission control before editing. After the changes, repeat the review in read-only mode against the updated diff.

For Cloud review, verify the remote environment’s effective permissions before relying on read-only isolation. Check required test outcomes separately from the review verdict.

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

**[Install or recover Heimdall](SETUP.md)** · [Understand the evidence model](HOW_IT_WORKS.md#what-counts-as-evidence)
