"""Codex CLI hooks for the Heimdall release repository."""

import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

SOL = "gpt-6.2-sol"
LUNA = "gpt-6-luna"
MODELS = {
    "heimdall_reasoning": SOL,
    "heimdall_reviewer": SOL,
    "heimdall_routine": LUNA,
}


def valid_spawn(event):
    args = event.get("tool_input")
    return (
        event.get("model") == SOL
        and not event.get("agent_id")
        and isinstance(args, dict)
        and isinstance(args.get("agent_type"), str)
        and args["agent_type"] in MODELS
        and args.get("model", MODELS[args["agent_type"]]) == MODELS[args["agent_type"]]
        and args.get("fork_context", False) is False
        and ("task_name" not in args or args.get("fork_turns") == "none")
    )


def spawn_succeeded(event):
    result = event.get("tool_response")
    if isinstance(result, str):
        try:
            result = json.loads(result)
        except json.JSONDecodeError:
            return False
    if not isinstance(result, dict):
        return False
    task_name = event["tool_input"].get("task_name")
    if task_name is not None:
        return isinstance(task_name, str) and bool(task_name) and result.get("task_name") == f"/root/{task_name}"
    return isinstance(result.get("agent_id"), str) and bool(result["agent_id"])


def receipt(event):
    session, turn = event.get("session_id"), event.get("turn_id")
    if not all(isinstance(value, str) and value for value in (session, turn)):
        return None
    directory = Path(tempfile.gettempdir()) / f"heimdall-routing-{os.getuid()}"
    directory.mkdir(mode=0o700, exist_ok=True)
    info = directory.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
        raise PermissionError("Unsafe Heimdall routing receipt directory")
    key = hashlib.sha256(json.dumps([session, turn]).encode()).hexdigest()
    return directory / key


def handle(event):
    match event.get("hook_event_name"):
        case "UserPromptSubmit":
            role = event.get("agent_type")
            expected = MODELS.get(role) if event.get("agent_id") else SOL
            if expected is None or event.get("model") != expected:
                return {
                    "decision": "block",
                    "reason": "Heimdall requires gpt-6.2-sol for the coordinator and the pinned model for each subagent role.",
                }
        case "PreToolUse":
            if not valid_spawn(event):
                return {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": (
                            "Use the Sol coordinator and the required model for the role: "
                            "heimdall_reasoning/heimdall_reviewer use gpt-6.2-sol; "
                            "heimdall_routine uses gpt-6-luna. Disable history forking."
                        ),
                    }
                }
        case "PostToolUse":
            if valid_spawn(event) and spawn_succeeded(event):
                path = receipt(event)
                if path is not None:
                    path.touch(mode=0o600)
        case "Stop":
            try:
                path = receipt(event)
                if path is not None:
                    path.unlink()
                    return {}
            except OSError:
                pass
            reason = (
                "No successful policy-compliant native subagent spawn was recorded "
                "for this turn. Delegate substantive work and use its result, "
                "or report the runtime blocker if delegation is unavailable."
            )
            if event.get("stop_hook_active"):
                return {"continue": False, "stopReason": reason, "systemMessage": reason}
            return {"decision": "block", "reason": reason}
    return {}


if __name__ == "__main__":
    print(json.dumps(handle(json.load(sys.stdin))))
