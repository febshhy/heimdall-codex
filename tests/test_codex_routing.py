import json
from pathlib import Path
import subprocess
import sys
try:
    import tomllib
except ModuleNotFoundError:  # Python 3.9 and 3.10
    tomllib = None
import unittest


ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / ".codex" / "model-routing.py"


class RoutingHookTests(unittest.TestCase):
    def run_hook(self, event):
        result = subprocess.run(
            [sys.executable, str(HOOK)],
            input=json.dumps(event),
            text=True,
            capture_output=True,
            check=True,
        )
        return json.loads(result.stdout)

    def assert_allowed(self, event):
        self.assertEqual(self.run_hook(event), {})

    def assert_denied(self, event):
        output = self.run_hook(event)
        self.assertEqual(output["hookSpecificOutput"]["hookEventName"], "PreToolUse")
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def spawn_event(self, **tool_input):
        return {
            "hook_event_name": "PreToolUse",
            "tool_name": "collaborationspawn_agent",
            "model": "gpt-6.2-sol",
            "tool_input": {
                "agent_type": "heimdall_routine",
                "task_name": "bounded_task",
                "fork_turns": "none",
                **tool_input,
            },
        }

    def test_allows_configured_v2_spawn(self):
        for role in ("heimdall_reasoning", "heimdall_reviewer", "heimdall_routine"):
            with self.subTest(role=role):
                self.assert_allowed(self.spawn_event(agent_type=role))

    def test_denies_spawn_from_non_sol_coordinator(self):
        event = self.spawn_event()
        event["model"] = "gpt-6-luna"
        self.assert_denied(event)

    def test_denies_unconfigured_role(self):
        self.assert_denied(self.spawn_event(agent_type="other_role"))

    def test_denies_role_model_override(self):
        self.assert_denied(self.spawn_event(model="gpt-6.2-sol"))

    def test_denies_role_reasoning_effort_override(self):
        self.assert_denied(self.spawn_event(reasoning_effort="high"))

    def test_denies_missing_explicit_fork_turns(self):
        event = self.spawn_event()
        del event["tool_input"]["fork_turns"]
        self.assert_denied(event)

    def test_denies_legacy_fork_context_input(self):
        self.assert_denied(self.spawn_event(fork_context=False))

    def test_denies_missing_or_blank_task_name(self):
        event = self.spawn_event()
        del event["tool_input"]["task_name"]
        self.assert_denied(event)
        self.assert_denied(self.spawn_event(task_name="  "))

    def test_allows_routine_operational_tools(self):
        for tool_name in ("Bash", "apply_patch", "mcp__files__read"):
            with self.subTest(tool_name=tool_name):
                self.assert_allowed(
                    {
                        "hook_event_name": "PreToolUse",
                        "tool_name": tool_name,
                        "agent_id": "agent-123",
                        "agent_type": "heimdall_routine",
                        "model": "gpt-6-luna",
                    }
                )

    def test_denies_operational_tools_for_coordinator_and_other_roles(self):
        for identity in (
            {},
            {"agent_id": "agent-123", "agent_type": "heimdall_reasoning", "model": "gpt-6.2-sol"},
            {"agent_id": "agent-123", "agent_type": "heimdall_routine", "model": "gpt-6.2-sol"},
        ):
            with self.subTest(identity=identity):
                self.assert_denied(
                    {"hook_event_name": "PreToolUse", "tool_name": "Bash", **identity}
                )

    def test_ignores_unrelated_event_and_tool(self):
        self.assert_allowed(
            {"hook_event_name": "Stop", "tool_name": "collaborationspawn_agent"}
        )
        self.assert_allowed(
            {"hook_event_name": "PreToolUse", "tool_name": "Read"}
        )


@unittest.skipIf(tomllib is None, "tomllib config assertions require Python 3.11+")
class RuntimeConfigTests(unittest.TestCase):
    def test_v2_feature_and_single_bounded_pretool_hook(self):
        config = tomllib.loads((ROOT / ".codex" / "config.toml").read_text())
        self.assertEqual(config["features"]["multi_agent_v2"]["enabled"], True)
        self.assertEqual(
            config["features"]["multi_agent_v2"]["expose_spawn_agent_model_overrides"],
            False,
        )
        self.assertEqual(config["agents"]["max_concurrent_threads_per_session"], 8)
        self.assertNotIn("max_depth", config["agents"])
        self.assertNotIn("default_subagent_reasoning_effort", config["agents"])
        self.assertEqual(set(config["hooks"]), {"PreToolUse"})
        hook = config["hooks"]["PreToolUse"][0]
        self.assertEqual(
            hook["matcher"], "^(collaborationspawn_agent|Bash|apply_patch|mcp__.*)$"
        )
        self.assertEqual(hook["hooks"][0]["timeout"], 5)

    def test_role_models_effort_and_review_capabilities_are_configured(self):
        roles = {}
        for name in ("heimdall_reasoning", "heimdall_reviewer", "heimdall_routine"):
            roles[name] = tomllib.loads(
                (ROOT / ".codex" / "agents" / f"{name}.toml").read_text()
            )
        self.assertEqual(roles["heimdall_reasoning"]["model"], "gpt-6.2-sol")
        self.assertEqual(roles["heimdall_reasoning"]["model_reasoning_effort"], "high")
        self.assertEqual(roles["heimdall_routine"]["model"], "gpt-6-luna")
        self.assertEqual(roles["heimdall_routine"]["model_reasoning_effort"], "low")
        for name in ("heimdall_reasoning", "heimdall_reviewer"):
            self.assertNotIn("sandbox_mode", roles[name])
            self.assertEqual(
                roles[name]["features"],
                {
                    "shell_tool": False,
                    "request_permissions_tool": False,
                    "apps": False,
                    "plugins": False,
                },
            )
        self.assertIn("evidence-only", roles["heimdall_reviewer"]["developer_instructions"])
        self.assertIn("Do not run commands", roles["heimdall_reasoning"]["developer_instructions"])


if __name__ == "__main__":
    unittest.main()
