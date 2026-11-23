---
name: software-factory
description: Orchestrate software delivery from a user goal through requirements, architecture, coding, independent review, tests and graph-based acceptance. Trigger for building, editing, debugging or refactoring software.
---

# AI software factory — coordinator lifecycle

**Authority:** only the main Codex agent orchestrates, schedules, integrates, and accepts; workers execute bounded nodes. Approved behavior stays with `$requirements`/reviewed `LAWS.bend`, domain and GUI contracts with their skills, verification with `$testing`, and delegated A/E/R with `$graph-protocol`. No worker approves new product policy.

Run research, planning, and build by default for software changes. Select and
read the applicable skills before their stage. Reassess them as scope changes
and pass the applicable method to each worker in R.

```text
Research → inspect requirements, source, and existing checks
  → Plan → define A/E/R, dependency gates, and verification
    → Build → dispatch ready nodes, verify, review, and integrate
      → Follow the target repository's delivery policy and user scope
        → Required delivery: merge to trunk → verify local sync and cleanup → report
```

Use external research where it resolves a material uncertainty. Scale the plan
from a single inline node to a schema-3 graph. Proceed into authorized build
after planning unless the user requested a plan only or a decision or approval
blocks the affected work.

## Classification and design

Use `$graph-protocol` by default for every task.

- **Single node:** a bounded read or routine command → include A/E/R and the expected output in the native subagent prompt.
- **Schema 3:** multiple dependent nodes or any delegated WRITE → record explicit owners, named output edges, A/E/R prompts, file ownership and verification argv.
- **Critical:** auth, security, money, migrations, destruction, consequential correctness → stronger evidence, rollback/recovery and approval where required; not automatically more agents.

Determine depth from impact if wrong, contract significance and existing detection strength (`AGENTS.md` selective audit). Use `$requirements` for material ambiguity, `$software-design-thinking` for domain structure, `$gui-design-thinking` for functional UI, `$visual-design` for presentation, `$content-writing` for substantive copy, `$evidence-research` for blocking external evidence, `$adr` for hard-to-reverse decisions. Keep unknowns explicit; no invented behavior or requirements. For structure use `$repository-work` tidy sequencing, bounded to the requested work; update governing design graph first when its contracts change.

## Delegated graph execution

```text
Plan A/E/R → scripts/factory init --plan <plan.json> --graph .work/graphs/<task>.json
  → ready? → prompt → begin / run → end --return → independent reviewer
    → actual tests/diff → scripts/factory validate --graph <record>
```

Dispatch only ready nodes; missing/failed/disputed predecessors block successors. READ/RUN use `run --return -- <argv>`; WRITE uses `prompt`, `begin` and `end --return`. Use the project-scoped roles in AGENTS.md. Independent review uses `heimdall_reviewer`. Check different identities and actual observations: a role label does not enforce independence. **Factory leases an entire Git worktree:** serialize nodes in one worktree, even disjoint files. Parallel WRITE requires prepared isolated worktrees, disjoint ownership and deliberate integration. Retry a failed node at most once after relevant correction. Every task requires a substantive subagent result. Apply the role/model routing in the governing AGENTS.md. Read `references/LIFECYCLE.md` for examples and critical release boundary.

## Selected Bend2 gate

```text
User-reviewed LAWS.bend (+ normative SPEC.bend assumptions)
  → model/proof WRITE → repository-wide scripts/factory proof passes with this pair
    → production WRITE → model-to-production conformance
      → integration/effect checks → final acceptance
```

Smoke proof never qualifies. Law or normative-assumption changes return to operator approval; do not silently replace failed formal verification with tests. If Bend unavailable or model cannot faithfully express selected scope, block or request explicit rescope. Other behavior uses ordinary approved requirements and tests.

## Acceptance and report

Follow the target repository's governing delivery policy. This installed skill
does not impose the release repository's policy on other projects. When delivery
is required, load the repository-work Git and PR procedure before creating a
task branch. Local verification is an input to delivery. Keep the task active
through independent review, verified trunk merge, local sync, and branch
cleanup. An open, queued, or blocked PR remains pending. Report a concrete
blocker if any required step cannot finish.

Run the actual applicable build/lint/tests, inspect Git diff and independent delegated-WRITE review, then validate every planned node and schema-3 return. Reject missing evidence, contradicting observation, required but absent review, invalid graph, or failed checks. Graph comparison is not application correctness. Report changed paths, approved requirement coverage, executed commands/results, review/evidence, unresolved risks and approvals. Include source-derived call-graph slices when `AGENTS.md` requires them; mark stale/unverified evidence, use the project's inspected revision and keep logs in `.work/`. Never claim a command/proof ran without observation, delete required checks to save tokens, or copy full logs into worker prompts. `jq` is required by the controller; optional tools never change the A/E/R contract.
