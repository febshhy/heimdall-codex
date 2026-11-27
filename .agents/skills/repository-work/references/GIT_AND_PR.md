# Git and Pull-Request Procedure

## 1. Workspace and branches

Use trunk-based development. Use the integration branch defined in `AGENTS.md`
or repository policy, defaulting to `main`. Fetch the remote integration branch
and confirm its current tip before creating a task branch or reusing an assigned
checkout. Reuse an assigned branch and worktree when available. Start a new task
branch from the confirmed remote trunk. Keep each task branch only as long as
delivery requires.

Do not commit or push directly to the integration branch during ordinary task work.

Use the assigned branch and workspace when they exist.

Use one short-lived branch for one reviewable task.

Use the configured branch prefix. Include the task identifier when available.

Use one active writer for one workspace.

Use separate worktrees for concurrent writers.

Keep independent tasks on separate branches.

Never discard work from another task.

Do not use `git reset --hard` without explicit authorization.

Do not use `git clean -fd` without explicit authorization.

Do not use `git push --force`.

Use `--force-with-lease` only for an explicitly authorized history rewrite.

## 2. Change discipline

Implement the requested behavior and necessary support changes.

Avoid unrelated refactoring, formatting, and dependency changes.

Change a lockfile only when a required dependency change changes it.

Stage only files that belong to the task.

Do not use `git add -A` in a shared or dirty workspace.

## 3. Commits

Use Conventional Commits 1.0.0.

Use this format:

```text
type(scope): imperative description
```

Allowed types are `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, and `revert`.

Use a short scope when it improves meaning.

Start the description with a lowercase imperative verb.

Do not end the subject with a period.

Keep the complete subject at or below 72 characters.

Use a commit body when the reason or tradeoff needs explanation.

When a delegated node produced the change, add the trailers `Node: <task_name>` and `Evidence: <log or packet path>`.

Use `Refs: TASK-123` when a task identifier exists.

Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.

Use the configured agent identity.

Do not impersonate a human author or reviewer.

Before each commit, run:

```text
git status --short
git diff --check
git add -- <explicit-paths>
git diff --cached --check
git diff --cached
```

Review the staged diff before the commit.

## 4. Pull requests

Push only the task branch.

Use one pull request for one coherent change.

Use a Conventional Commit title.

Include the task, summary, validation results, risks, and rollback notes when they apply.

Identify schema, migration, compatibility, and feature-flag changes.

Do not approve your own work.

Do not bypass required reviews, CI checks, or branch protection.

Use the configured merge method and merge queue.

## 5. Agent-led acceptance and merge

The coordinator owns PR delivery. A request to push or deliver repository
changes authorizes the routine PR path through merge and cleanup unless the
user limits the scope. Confirm the result. Routine PRs require independent agent
review and passing checks. Skip a separate human sign-off where the host permits
agent-led merge. Apply a repository's explicit policy and required host checks.

Plan the PR work as dependencies with named outputs:

- The author (coordinator for small tasks, or a bounded WRITE worker) hands off
  the candidate commit, its scope, and relevant requirements.
- A separate read-only reviewer inspects the candidate diff and returns findings
  and a verdict tied to the reviewed commit. Run required checks against that
  exact candidate head and verify their observed results. Review and checks may
  run independently against the same candidate. If the head changes, repeat
  both. A subagent's verdict is review evidence, not a hosting-provider approval
  under another person's identity.
- Use one independent Luna collector to prepare a compact candidate evidence
  packet with the actual diff, relevant source or an exact source slice, the
  candidate SHA, and observed required checks. For schema-3 factory records,
  use `candidate-capture` to bind base, HEAD, index state, and the complete
  prospective Git tree. Capture the actual base-to-candidate diff. For a dirty
  capture that is later committed, bind it with `candidate-bind` to the exact
  later commit, captured parent, tree, and base before review. Tie check logs to
  exact declared argv arrays and candidate identity. The review verdict names
  the WRITE node, the independent reviewer owner, and candidate, diff, and
  check digests. Keep the Sol review independent and have it consume this
  packet. The controller may carry the same packet into routine delivery while
  the base and candidate identities remain unchanged. If either identity
  changes, refresh affected evidence and review the new head.
- The coordinator resolves findings, checks review and test evidence against the
  current PR head, and confirms required host checks or merge-queue eligibility.
  For work using schema 3, keep the premerge candidate graph in its own record
  ending at candidate evidence. Run `scripts/factory validate` on that record
  before accepting the candidate. Pass the accepted reviewed head and candidate
  validation evidence as named inputs to a separate schema-3 delivery record.
  That graph records the host merge observation followed by final cleanup
  verification and is validated after both observations are complete. Each
  node takes its own start and finish snapshot. The graph does not require every
  node to observe the same `HEAD`.
- The accepted head authorizes the merge node within the task's remote scope.
  Use a head-checked merge or the configured merge queue. Observe the host's
  merge result in a HEAD-stable `RUN` node and record the PR URL and merge
  commit when available. Accept that observation before starting local checkout
  synchronization or task-ref cleanup.
- After the host confirms the accepted head merged, the same authorized Luna
  controller performs the fetch, checkout synchronization, and scoped ref
  cleanup outside an active factory node and lease. Preserve each exact command
  outcome in a named handoff to the final observation. Wait for queued merges
  before starting cleanup. Then run a final HEAD-stable read-only node against
  the post-sync worktree. It verifies the host merge, trunk and local checkout
  sync, and safe disposition of task-owned local and remote refs. Never change
  the worktree root or `HEAD` during a `READ` or `RUN` node. If a command
  outcome or ref state differs from the accepted merge result, stop and return
  that evidence for coordinator resolution.

In the delegated A/E/R plan, A carries these outputs along dependency edges.
E covers wrong scope or base, missing evidence, and misread acceptance criteria.
Use schema 3 for every delegated WRITE and for work with multiple dependent
nodes. A single eligible read or routine command can carry its A/E/R inline in
the prompt. For each schema-3 node, R includes its bounded subgraph, applicable
method, exact verification argv arrays, inputs, and reason for the work. Include
the candidate commit in review and verification inputs. Give concurrent WRITE
nodes separate worktrees.

After each delegated node returns, compare its structured A/E/R with the
delegated subgraph before accepting its outputs or dispatching a successor.
Every delegated WRITE also requires independent review and passing checks.

If the head changes, repeat review and verification for the new head. If the
base changes, recheck the affected integration evidence against the current
base or use the required merge queue. Fix actionable findings, rerun affected
checks, and reevaluate the gate. Missing evidence or a host rule that prevents
agent-led merge leaves the PR open. An open, queued, or blocked PR is pending,
not a completed delivery. Report the blocking rule or failed check.

## 6. Post-merge cleanup

Verify that the host reports the PR merged into the integration branch. Fetch
that branch and check that it contains the reported merge commit. This also
works for squash merges, where the original task commits may be absent.

After verification, delete the task-owned remote branch if the host has not
already deleted it. Confirm it still points to the reviewed head and has no
dependent PRs. Return the local checkout to the integration branch, fetch it,
and fast-forward local integration when safe. Verify it contains the reported
merge commit. Remove the local task branch and any task-created worktree only
after checking for unrelated or uncommitted work. If local sync or cleanup
cannot finish safely, preserve affected work and report delivery as pending.
Create tags only when the task explicitly authorizes a release or tag.

Check local refs and query the remote directly after cleanup. Confirm the task
branch is absent on both, and report any cleanup blocker with its ref. For an
older branch, verify its tip against a merged PR and check for worktrees and
dependent PRs before retiring it. If a squash merge left unique commit IDs,
verify that the merged PR covered the branch tip before deleting the local ref.

## 7. Completion report

Report the task identifier when it exists.

Report the branch and final commit SHA when commits exist.

Report the pull-request link when it exists.

Report validation commands and results.

Report known risks and outstanding work.

Report merge or deployment status when you know it.
