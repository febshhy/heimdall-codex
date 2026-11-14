# Install Heimdall

**Download Heimdall once, preview the changes to your project, apply the approved plan, and start Codex.** Project installation keeps the engineering instructions with your code. Global installation makes shared guidance available to your Linux user.

[Overview](../README.md) · [First task](USAGE.md#first-session) · [How it works](HOW_IT_WORKS.md)

## Prerequisites

Run the installer in **Linux Bash**. On Windows, use **WSL**; these are not Command Prompt or PowerShell commands. Native Windows installation is not provided.

You need Bash 4.4+, Python 3.9+, Git, `jq`, and standard Linux tools such as `flock`, `sha256sum`, `timeout`, `find`, `sort`, and core utilities. Install and authenticate [Codex CLI](https://github.com/openai/codex) separately.

Check the main tools:

```bash
bash --version
python3 --version
git --version
jq --version
codex --version
```

For Ubuntu or Debian, install the common system dependencies if missing:

```bash
sudo apt update
sudo apt install bash python3 git jq util-linux coreutils findutils
```

Use `sudo` only to install system packages. **Run Heimdall as your normal user.** Package names can differ on other Linux distributions.

## Get the source

Choose one method to obtain Heimdall's source. Keep the checkout or extracted directory **outside your application repository**. All three methods supply the same `HEIMDALL_SRC` variable used in the installation steps below.

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

Forking alone does not install Heimdall. Continue with [Choose a setup path](#choose-a-setup-path) and use the local source directory shown above.

### Download ZIP

On the [Heimdall GitHub repository](https://github.com/febshhy/heimdall-codex), choose **Code → Download ZIP**. Extract it outside your application, then point `HEIMDALL_SRC` to the directory containing `scripts/heimdall`:

```bash
HEIMDALL_SRC="/path/to/extracted/heimdall-codex"
```

Regardless of the method, inspect the source before running scripts. Teams can select an approved commit in a Git checkout. A commit identifies source content; it does not by itself establish publisher trust. Run the remaining commands in the same Bash session, or set `HEIMDALL_SRC` again in a new session.

## Choose a setup path

| Your situation | Next step |
| --- | --- |
| Existing team repository | [Existing project](#existing-project) |
| New application directory | [New project](#new-project) |
| Personal guidance shared across repositories | [Global installation](#global-installation) |

Use one scope that matches your needs. Project and global instructions may both exist, but their ownership should be clear.

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

`--integrate-agents` permits a bounded addition to existing `AGENTS.md` instructions. It does not replace unrelated instructions. Setup rejects unmanaged-file collisions and stale or option-mismatched plans.

If the worktree contains changes, commit or stash them before preview. An explicit `--allow-dirty` exception is available, but requires careful review and the same option on preview and apply.

## New project

Choose a path that is absent or empty. Heimdall can initialize Git and install its instructions; it does not select a framework or generate application code.

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

## Global installation

For shared user-level instructions instead of project-managed files:

```bash
bash "$HEIMDALL_SRC/install.sh" --global --integrate-agents --dry-run
bash "$HEIMDALL_SRC/install.sh" --global --integrate-agents
bash "$HOME/.local/share/heimdall/release/install.sh" --global --verify
```

Review the preview before applying. Global installation does not modify application repositories or install their project-specific reviewer configuration. It uses the default Codex home directory, not a custom `CODEX_HOME`.

## Start Codex

After project installation, open the target repository and run:

```bash
cd /path/to/your-project
codex
```

For an existing codebase, Codex can use `$project-adoption` and `$software-design-thinking` to inspect real source and trace relevant execution paths. The installer does not invent architecture graphs or historical decisions. [Start with a read-only task](USAGE.md#first-session).

## Verify, recover, or remove

Verify project installation at any time:

```bash
bash .heimdall/install.sh --verify
```

This checks installed instructions, not application correctness. If installation is interrupted, inspect the saved transaction and its recovery choices:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" status --project /path/to/your-project
bash "$HEIMDALL_SRC/scripts/heimdall" recover --project /path/to/your-project
```

After reviewing the state, request a recorded revert if needed:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" recover --project /path/to/your-project --revert
```

Recovery preserves unfamiliar edits and may require manual resolution. It does not guarantee removal of every empty directory or Git metadata.

Remove a current installation when appropriate:

```bash
# From the application root:
bash .heimdall/install.sh --remove

# Or, for a global installation:
bash "$HOME/.local/share/heimdall/release/install.sh" --global --remove
```

Installation, verification, and removal do not modify or delete your application's `docs/` directory.

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

## Security and permissions

Codex can access resources granted to its execution environment. Heimdall instructs agents not to read secret values, but instructions cannot enforce isolation from credentials readable by the same OS identity. For confidential credentials, use a separately secured environment or external broker with scoped access. [Read the credential boundary](../docs/security/CREDENTIAL_BOUNDARY.md).

Publishing new end-user documents under project `docs/` requires a separate, authorized documentation task. Setup does not populate this directory.

## Optional Bend 2 proofs

For selected rules that justify formal verification, enable Bend 2 in both preview and apply:

```bash
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --with-bend2
bash "$HEIMDALL_SRC/scripts/heimdall" start --project . --with-bend2 --apply
```

Use a trusted Bend 2 executable. Approved `LAWS.bend` specify the selected formal behavior, while `PROOF.bend` supplies proof evidence for the model. Production still needs conformance checks. The smoke proof only checks the tool. [Read the proof workflow](../proofs/README.md).

**[Try a task](USAGE.md)** · [Understand the method](HOW_IT_WORKS.md) · [Back to Heimdall](../README.md)
s