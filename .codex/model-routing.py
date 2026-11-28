"""Route covered Codex tools to the configured Heimdall roles."""

import json
import sys

SOL = "gpt-6.2-sol"
LUNA = "gpt-6-luna"
ROLES = {"heimdall_reasoning", "heimdall_reviewer", "heimdall_routine"}
OPERATIONAL_TOOLS = {"Bash", "apply_patch"}


def deny(reason):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def is_operational_tool(tool_name):
    return tool_name in OPERATIONAL_TOOLS or (
        isinstance(tool_name, str) and tool_name.startswith("mcp__")
    )


def valid_spawn(event):
    args = event.get("tool_input")
    return (
        event.get("model") == SOL
        and not event.get("agent_id")
        and isinstance(args, dict)
        and isinstance(args.get("agent_type"), str)
        and args["agent_type"] in ROLES
        and isinstance(args.get("task_name"), str)
        and bool(args["task_name"].strip())
        and args.get("fork_turns") == "none"
        and "model" not in args
        and "reasoning_effort" not in args
        and "fork_context" not in args
    )


def valid_routine_agent(event):
    return (
        bool(event.get("agent_id"))
        and event.get("agent_type") == "heimdall_routine"
        and event.get("model") == LUNA
    )


def handle(event):
    if event.get("hook_event_name") != "PreToolUse":
        return {}

    tool_name = event.get("tool_name")
    if tool_name == "collaborationspawn_agent":
        if valid_spawn(event):
            return {}
        return deny(
            "Use the Sol coordinator, a configured Heimdall role, explicit fork_turns=none, and a task_name; role model and effort come from role configuration."
        )

    if is_operational_tool(tool_name):
        if valid_routine_agent(event):
            return {}
        return deny("Operational tools must be run by the GPT-6 Luna heimdall_routine role.")

    return {}


if __name__ == "__main__":
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        event = {}
    print(json.dumps(handle(event)))
