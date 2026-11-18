# Git and Pull-Request Procedure

## 1. Workspace and branches

Use the integration branch defined in `AGENTS.md` or repository policy. If none is defined, treat `main` as the default integration branch.

Do not commit or push directly to the integration branch during ordinary task work.

Use the assigned branch and workspace when they exist.

Use one short-lived branch for one reviewable task.

Use `agent/<task-id>-<short-slug>` when the task has an identifier.

Use `agent/<short-slug>` when the task has no identifier.

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
  and a verdict tied to the reviewed commit. The coordinator verifies observed
  test results. Review and test execution may run independently against the same
  candidate. A subagent's verdict is review evidence, not a hosting-provider
  approval under another person's identity.
- The coordinator resolves findings, checks review and test evidence against the
  current PR head, and confirms required host checks or merge-queue eligibility.
  For delegated WRITEs, also compare the returned A/E/R records with the delegated
  subgraph and validate the schema-3 factory record before acceptance.
- The accepted head authorizes the merge node within the task's remote scope.
  Use a head-checked merge or the configured merge queue. Observe the host's
  merge result and record the PR URL and merge commit when available.

In the delegated A/E/R plan, A carries these outputs along dependency edges.
E covers wrong scope or base, missing evidence, and misread acceptance criteria.
For each delegated node, R includes its bounded subgraph, applicable method,
verification command, and reason for the work. Include the candidate commit in
review and verification inputs. Give concurrent WRITE nodes separate worktrees.

If the head changes, repeat review and verification for the new head. If the
base changes, recheck the affected integration evidence against the current
base or use the required merge queue. Fix actionable findings, rerun affected
checks, and reevaluate the gate. Missing evidence or a host rule that prevents
agent-led merge leaves the PR open. Report the blocking rule or failed check.

## 6. Post-merge cleanup

Verify that the host reports the PR merged into the integration branch. Fetch
that branch and check that it contains the reported merge commit. This also
works for squash merges, where the original task commits may be absent.

After verification, delete the task-owned remote branch if the host has not
already deleted it. Confirm it still points to the reviewed head and has no
dependent PRs. Return the local checkout to the integration branch and
fast-forward it when safe. Remove the local task branch and any task-created
worktree only after checking for unrelated or uncommitted work. If cleanup would
discard work or affect another task, preserve the branch and report the reason.
Create tags only when the task explicitly authorizes a release or tag.

## 7. Completion report

Report the task identifier when it exists.

Report the branch and final commit SHA when commits exist.

Report the pull-request link when it exists.

Report validation commands and results.

Report known risks and outstanding work.

Report merge or deployment status when you know it.
