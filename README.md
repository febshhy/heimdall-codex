# Heimdall

**Trace the change. Preserve the contract. Verify the result.**

[![Codex](https://img.shields.io/badge/for-Codex-775726?style=flat-square&labelColor=202A30)](https://developers.openai.com/codex/ide)
[![MIT license](https://img.shields.io/badge/license-MIT-775726?style=flat-square&labelColor=202A30)](LICENSE)

Heimdall gives Codex a disciplined way to work in real codebases. Use it with Codex CLI, the Codex IDE extension, Codex in the ChatGPT desktop app (Local, Worktree, or Cloud), or Codex on the web at [chatgpt.com/codex](https://chatgpt.com/codex/) to trace affected paths, make focused changes, and show evidence behind the result. It works with your existing language, framework, and tests.

![A dimensional illustration of a guarded hall beside a bridge crossing a misty gorge, inspired by Heimdall’s watch at Bifröst.](marketing/heimdall-watch.jpg)

**[Get started](marketing/SETUP.md)** · [See the method](marketing/HOW_IT_WORKS.md) · [Try a task](marketing/USAGE.md)

## Why Heimdall?

A team asks Codex to make confidential reports visible only to authorized members. The patch filters the reports page and adds a passing test. The export endpoint still serves the full report, and a scheduled job still emails it. The patch looks ready until someone traces the other ways a report leaves the system.

Teams already use prompts, repository instructions, CI, and pull-request review to catch gaps like this. A prompt can ask Codex to check every caller. CI can verify the paths its tests cover. Review can catch a missing path if someone knows to look for it. The work of connecting the request to every affected path still has to happen, and a green check gives reviewers little visibility into that search.

**Heimdall makes that work part of the repository’s engineering process.** The goal is to carry an approved change from intent to implementation with enough evidence for someone else to review the result. For the report rule, that means tracing how reports are read, exported, and delivered, locating where authorization belongs, and checking both allowed and denied access on the affected paths. [Walk through the access-rule example](marketing/HOW_IT_WORKS.md#example-a-shared-access-rule).

The template gives Codex shared methods for requirements, domain and UI behavior, data, and verification. Codex handles small changes directly. When work spans agents, Graph Protocol makes ownership, inputs, and required outputs explicit. The coordinator checks the actual diff and test results, and delegated code changes get independent review. Later sessions can follow the same process using the project’s own tools and conventions.

<picture>
  <source media="(max-width: 640px)" srcset="marketing/heimdall-flow-mobile.svg">
  <img src="marketing/heimdall-flow.svg" alt="Four stages of engineering work connected by one route: Intent, Source paths, Focused change, and Evidence. Evidence records what was verified, including failures and unknowns.">
</picture>

The [engineering playbook](marketing/ENGINEERING_PLAYBOOK.md) shows how to apply these methods to a single change, from defining its contract through testing recovery.

## Start in an existing project

Run the installer commands in **Linux Bash** or **WSL on Windows**. You need Git, Bash 4.4+, Python 3.9+, `jq`, and a signed-in Codex client. In the desktop app, choose Local or Worktree for local project files, or Cloud for a remote task. [Check the setup prerequisites](marketing/SETUP.md#prerequisites) and [app setup steps](marketing/SETUP.md#start-codex).

**1. Get Heimdall outside your application repository.**

```bash
mkdir -p "$HOME/tools"
git clone https://github.com/febshhy/heimdall-codex.git "$HOME/tools/heimdall-codex"
```

**2. Preview changes to your clean Git project.**

```bash
cd /path/to/your-project
bash "$HOME/tools/heimdall-codex/scripts/heimdall" start --project . --integrate-agents
```

**3. Review the plan, apply it, and verify installation.**

```bash
bash "$HOME/tools/heimdall-codex/scripts/heimdall" start --project . --integrate-agents --apply
bash .heimdall/install.sh --verify
```

Open the project in Codex CLI with `codex`, in the IDE extension, or in the ChatGPT desktop app and choose Local or Worktree. For Codex on the web, connect the repository at [chatgpt.com/codex](https://chatgpt.com/codex/) and follow the [app setup steps](marketing/SETUP.md#start-codex).

For a [new project](marketing/SETUP.md#new-project) or recovery, use the [setup guide](marketing/SETUP.md).

## Give Codex a first task

> Inspect the source and tests for the behavior I want to change. Trace the relevant production path using real names. Identify the shared contracts, failure cases, and unknowns. Recommend the smallest change and how to verify it. Do not edit files yet.

Review the findings before authorizing implementation. [Use prompts for bugs, UI, databases, writing, and coordinated work](marketing/USAGE.md#task-examples).

## Keep decisions and evidence in your control

Heimdall provides instructions, skills, and optional task-handoff checks. Your project defines approved behavior; its tools provide test and runtime evidence. Codex acts within the permissions you give it. Use an isolated execution environment for sensitive credentials.

[Understand responsibilities and verification](marketing/HOW_IT_WORKS.md#what-counts-as-evidence) · [Read security and setup guidance](marketing/SETUP.md#security-and-permissions) · [MIT license](LICENSE)

## The name behind Heimdall

<a href="https://commons.wikimedia.org/wiki/File:Heimdal_listening_next_to_Bifrost.jpg">
  <img src="https://upload.wikimedia.org/wikipedia/commons/1/17/Heimdal_listening_next_to_Bifrost.jpg" width="184" alt="Constantin Hansen's painting of Heimdall listening beside the rainbow bridge, with Gjallarhorn resting in his hand.">
</a>

*Heimdal listening next to Bifrost*, Constantin Hansen. [Artwork and public-domain source](https://commons.wikimedia.org/wiki/File:Heimdal_listening_next_to_Bifrost.jpg).

Heimdall is named after the watchman of Bifröst.
