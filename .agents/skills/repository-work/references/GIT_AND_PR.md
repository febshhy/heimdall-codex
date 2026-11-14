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

## 5. Completion report

Report the task identifier when it exists.

Report the branch and final commit SHA when commits exist.

Report the pull-request link when it exists.

Report validation commands and results.

Report known risks and outstanding work.

Report merge or deployment status when you know it.
