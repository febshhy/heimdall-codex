#!/usr/bin/env bash
set -euo pipefail

exec jq -cRs '
  def deny($reason): {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  };
  try fromjson catch null
  | if type != "object" then {} else . end
  | if .hook_event_name != "PreToolUse" then {}
    elif .tool_name == "collaborationspawn_agent" then
      if (.agent_id? == null or (.agent_id | type == "string" and length == 0))
        and .model == "gpt-6.2-sol"
        and (.tool_input | type == "object")
        and (.tool_input.agent_type | type == "string" and . == "heimdall_reasoning" or . == "heimdall_reviewer" or . == "heimdall_routine")
        and (.tool_input.task_name | type == "string" and test("\\S"))
        and .tool_input.fork_turns == "none"
        and (.tool_input | has("model") | not)
        and (.tool_input | has("reasoning_effort") | not)
        and (.tool_input | has("fork_context") | not)
      then {}
      else deny("Use the Sol coordinator, a configured Heimdall role, explicit fork_turns=none, and a task_name; role model and effort come from role configuration.") end
    elif ((.tool_name | type == "string") and (.tool_name == "Bash" or .tool_name == "apply_patch" or (.tool_name | startswith("mcp__")))) then
      if ((.agent_id | type == "string" and length > 0)
        and .agent_type == "heimdall_routine"
        and .model == "gpt-6-luna")
      then {} else deny("Operational tools must be run by the GPT-6 Luna heimdall_routine role.") end
    else {} end
'
