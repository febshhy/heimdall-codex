# Install Heimdall

**Download Heimdall once, preview the changes to your project, apply the approved plan, and start Codex.** Installation keeps the engineering instructions with your code.

[Overview](../README.md) · [First task](USAGE.md#first-session) · [How it works](HOW_IT_WORKS.md)

## Prerequisites

Run the installer in **Linux Bash**. On Windows, run the installer in **WSL**.

The direct `bash install.sh` installer requires Bash 4.4+, Git, `jq`, and system utilities including `flock`, `sha256sum`, `timeout`, `find`, `sort`, and core utilities. Python 3.9+ is used by the normal `scripts/heimdall` lifecycle commands in this guide. Heimdall's shell hook uses Bash and `jq`. You also need a signed-in Codex client: [Codex CLI](https://github.com/openai/codex), the [Codex IDE extension](https://developers.openai.com/codex/ide), Codex in the ChatGPT desktop app, or Codex Cloud on the web. The CLI is optional. Cloud use also requires Cloud access and a connected repository that the task environment can use.

Check the main tools:

```bash
bash --version
python3 --version
git --version
jq --version
```

If you use Codex CLI, check it with `codex --version`. Sign in to the IDE extension or desktop app when using those clients. For Codex Cloud, sign in to ChatGPT and confirm the connected account can access the project repository.

For Ubuntu or Debian, install the common system dependencies if missing:

```bash
sudo apt update
sudo apt install bash python3 git jq util-linux coreutils findutils
```

Use `sudo` only to install system packages. **Run Heimdall as your normal user.**

## Get the source

Choose one method to obtain the Heimdall template. You can name the template
and application directories independently. Keep the template outside your
application repository and set `HEIMDALL_SRC` to its actual root. Pass your
application's Git root to `--project` for an existing project.

| Method | Use it when |
| --- | --- |
| [Clone the original repository](#clone-the-original-repository) | You want to install Heimdall without maintaining your own copy on GitHub. |
| [Fork and clone](#fork-and-clone) | You want to customize Heimdall, keep your own changes, or contribute upstream. |
| [Download ZIP](#download-zip) | You want a source snapshot without a local Git checkout. |

### Clone the original repository

Clone the [Heimdall GitHub repository](https://github.com/febshhy/heimdall-codex) into a tools directory:

```bash
mkdir -p "$HOME/tools"
git clone https://github.com/febshhy/heimdall-codex.git "$HOME/tools/heimdall-codex"
HEIMDALL_SRC="$HOME/tools/heimdall-codex"
```

### Fork and clone

1. Open [Heimdall on GitHub](https://github.com/febshhy/heimdall-codex) and select **Fork**.
2. Choose the owner, keep or change the repository name, then select **Create fork**.
3. Clone **your fork** into a tools directory. Replace `YOUR-USERNAME` and the repository name if you changed it:

```bash
mkdir -p "$HOME/tools"
git clone https://github.com/YOUR-USERNAME/heimdall-codex.git "$HOME/tools/heimdall-codex"
HEIMDALL_SRC="$HOME/tools/heimdall-codex"
```

Optionally, add the original repository as `upstream` so you can fetch later changes:

```bash
git -C "$HEIMDALL_SRC" remote add upstream https://github.com/febshhy/heimdall-codex.git
git -C "$HEIMDALL_SRC" remote -v
```

`origin` should point to your fork and `upstream` to the original repository. Add `upstream` only once. Review incoming changes before incorporating them into a customized fork. See [GitHub's guide to syncing a fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork).

Continue with [Choose a setup path](#choose-a-setup-path) and use the local source directory shown above.

### Download ZIP

On the [Heimdall GitHub repository](https://github.com/febshhy/heimdall-codex), choose **Code → Download ZIP**. Extract it outside your application, then point `HEIMDALL_SRC` to the directory containing `scripts/heimdall`:

```bash
HEIMDALL_SRC="/path/to/extracted/heimdall-codex"
```

Regardless of the method, inspect the source before running scripts. Teams can select an approved commit in a Git checkout. Run the remaining commands in the same Bash session, or set `HEIMDALL_SRC` again in a new session.

## Choose a setup path

| Your situation | Next step |
| --- | --- |
| Existing team repository | [Existing project](#existing-project) |
| New application directory | [New project](#new-project) |

## Existing project

Work from the root of a **clean Git repository**. The first command writes a saved installation plan outside the application and leaves project files unchanged.

```bash
cd /path/to/your-project
git status --short
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --integrate-agents
```

Read the planned file changes. Apply only after you approve them:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --integrate-agents --apply
bash .heimdall/install.sh --verify
git diff --stat
```

`--integrate-agents` permits a bounded addition to existing `AGENTS.md` instructions. Existing unrelated instructions stay in place. Setup rejects unmanaged-file collisions and stale or option-mismatched plans.

If the worktree contains changes, commit or stash them before preview. An explicit `--allow-dirty` exception is available, but requires careful review and the same option on preview and apply.

## New project

Choose a path that is absent or empty. Heimdall initializes Git and installs its instructions.

```bash
mkdir -p "$HOME/projects"
bash "$HEIMDALL_SRC/scripts/heimdall" start --project "$HOME/projects/my-app"
```

Review the plan, then apply and verify:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" start --project "$HOME/projects/my-app" --apply
cd "$HOME/projects/my-app"
bash .heimdall/install.sh --verify
```

Setup refuses unsafe nested repositories and populated directories without Git.

## Start Codex

Open the target repository in a local Codex client (CLI, IDE extension, or
desktop app in Local or Worktree mode). Trust the project so the client can
load its project-scoped settings and hooks. Start a **new Codex session** after
installation or update. Restart an existing session to load current
instructions and agent profiles.

The installer ships Heimdall's `.codex/agents/` profiles into the target
project. Configure its Codex settings, hooks, and execpolicy rules separately.
The clone's `.codex/config.toml` sets `workspace-write`, `on-request`, and
`auto_review` defaults when you open that clone as a trusted project in Codex
CLI. Its `PreToolUse` hook invokes `.codex/model-routing.sh` from the Git root
of the current directory. Review the changed hook in Codex's `/hooks` view
before trusting it. Opening the Heimdall clone does not configure your
application. Automatic review can approve or deny eligible approval requests.
It does not remove sandbox or managed policy restrictions. CLI options can
override configuration, and organization or system managed requirements can
constrain it.

In the desktop app, select **Approve for me** from the current chat's permissions control when it is available.

To opt into automatic review for an application with Codex CLI, run this from
the application repository:

```bash
codex --approve-for-me
```

**Codex CLI:**

```bash
cd /path/to/your-project
codex
```

**Codex IDE extension:** Install and sign in to the [Codex extension](https://developers.openai.com/codex/ide) in VS Code or a supported editor. Open the target repository, then open the Codex sidebar and start a chat.

**ChatGPT desktop app — Codex:** Open the app, select **Codex**, and choose the target repository. Choose **Local** to work in the current checkout, or **Worktree** to isolate changes in a separate Git worktree on your computer. For Worktree, commit the Heimdall installation so its repo instructions and skills are in the branch used to create the worktree. See OpenAI's [Codex environment modes](https://learn.chatgpt.com/docs/environments/modes) and [worktree guide](https://learn.chatgpt.com/docs/environments/git-worktrees).

**Codex on the web:** Open [chatgpt.com/codex](https://chatgpt.com/codex/) and start a Cloud task. In the desktop app, you can also choose **Cloud** when you want the same remote execution mode. Cloud tasks use a separate remote workspace, so first install Heimdall in your project, commit the installed files, and push them to the connected GitHub or GitLab repository. See OpenAI's [Codex Cloud environment guide](https://learn.chatgpt.com/docs/environments/cloud-environments) for setup steps.

If you do not have a cloud environment yet, create one from the environment picker or **Settings > Codex Cloud > Environments**. Select your repository, let Codex prepare and test the environment, and publish it. Include the project runtimes and tools your tasks need. If a Cloud task will run Heimdall's installer or factory commands, make the prerequisites listed above available in that Linux environment and make Heimdall's source available to the task, for example by adding its repository to the environment. Ask Codex to preview the install first, review the plan, then apply and verify it. Commit and push the installed files for future Cloud tasks. Review environment network access and repository permissions before starting tasks.

Store shared Cloud skills in the connected repository under `.agents/skills/`. Verify the effective settings and reviewer profiles in the Cloud task before relying on them. Review the task diff and open a PR to integrate it.

For an existing codebase, Codex can use `$project-adoption` and `$software-design-thinking` to inspect real source and trace relevant execution paths. [Start with a read-only task](USAGE.md#first-session).

## Verify, recover, or remove

These commands operate on Heimdall-managed files and preserve your application's `docs/` directory.

Verify the installed Heimdall files and Codex instruction integration:

```bash
bash .heimdall/install.sh --verify
```

If installation is interrupted, inspect the saved transaction and its recovery choices:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" status --project /path/to/your-project
bash "$HEIMDALL_SRC/scripts/heimdall" recover --project /path/to/your-project
```

After reviewing the state, request a recorded revert if needed:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" recover --project /path/to/your-project --revert
```

Resolve any reported conflicts manually. Inspect leftover directories and Git metadata before removing them.

Remove a current installation when appropriate:

```bash
bash .heimdall/install.sh --remove
```

## Resolve setup problems

| Problem | Next step |
| --- | --- |
| Missing Git, Python, `jq`, or system utility | Install the named prerequisite and rerun the preview. |
| Tools directory already exists | Inspect it instead of merging a new checkout into it. |
| `HEIMDALL_SRC` is unset | Set it to the downloaded source path in the current Bash session. |
| Fork clone fails | Check the fork URL, repository owner, and your access to the fork. |
| `upstream` remote already exists | Check `git -C "$HEIMDALL_SRC" remote -v`; do not add the same remote again. |
| Wrong project directory | Check `git rev-parse --show-toplevel` and use the repository root. |
| Dirty worktree or existing instruction conflict | Preserve your changes, review the planned integration, and preview again. |
| Saved plan is stale | Regenerate and review the plan before applying. |
| Installation was interrupted | Use `status`, then inspect the reported recovery action. |
| Codex cannot find the guidance | Verify the installation and start a new Codex session in the intended repository. |
| An obsolete Stop hook reports that `model-routing.py` is missing | Press Ctrl+C if Codex offers to retry the failed hook. Exit Codex, relaunch it from the repository, and review the current hook in `/hooks`. |

## Security and permissions

Use a separately secured environment or external broker with scoped access for confidential credentials. [Read the credential boundary](../docs/security/CREDENTIAL_BOUNDARY.md).

## Optional Bend 2 proofs

For selected rules that justify formal verification, enable Bend 2 in both preview and apply:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --with-bend2
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --with-bend2 --apply
```

Use a trusted Bend 2 executable. Approved `LAWS.bend` specify the selected formal behavior, while `PROOF.bend` supplies proof evidence for the model. Production still needs conformance checks. [Read the proof workflow](../proofs/README.md).

**[Try a task](USAGE.md)** · [Understand the method](HOW_IT_WORKS.md) · [Back to Heimdall](../README.md)
